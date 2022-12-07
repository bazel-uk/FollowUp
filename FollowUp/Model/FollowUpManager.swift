//
//  FollowUpManager.swift
//  FollowUp
//
//  Created by Aaron Baw on 30/12/2021.
//

import BackgroundTasks
import Combine
import Foundation
import RealmSwift

final class FollowUpManager: ObservableObject {

    // MARK: - Private Stored Properties
    
    var realm: Realm?

    // First, we check to see if a follow up store exists in our realm.
    // If one doesn't exist, then we create one and add it to the realm.
    // If a follow up store has been passed as an argument, than this supercedes any store that we find in the realm.
    var store: FollowUpStore

    var contactsInteractor: ContactsInteracting
    private var subscriptions: Set<AnyCancellable> = .init()
    private var notificationManager: NotificationManaging
    
    // MARK: - Public Properties
    public var contactsInteractor: ContactsInteracting = ContactsInteractor()

    // MARK: - Initialization
    init(
        contactsInteractor: ContactsInteracting? = nil,
        notificationManager: NotificationManaging = NotificationManager(),
        store: FollowUpStore? = nil,
        realmName: String = "followUpStore"
    ) {
        // The Schema (and Realm object) needs to be initialised first, as this is referenced in order to fetch any existing FollowUpStores from the Realm DB.
        let realm = Self.initializeRealm()
        self.realm = realm
        self.contactsInteractor = contactsInteractor ?? ContactsInteractor(realm: realm)
        // First, we check to see if a follow up store exists in our realm.
        // If one doesn't exist, then we create one and add it to the realm.
        // If a follow up store has been passed as an argument, than this supercedes any store that we find in the realm.
        self.store = store ?? FollowUpStore(realm: realm)

        self.notificationManager = notificationManager
        self.subscribeForNewContacts()
        self.objectWillChange.send()
    }

    // MARK: - Methods
    private func subscribeForNewContacts() {
        self.contactsInteractor
            .contactsPublisher
            .sink(receiveValue: { newContacts in
                self.store.updateWithFetchedContacts(newContacts)
            })
            .store(in: &self.subscriptions)
    }
    
    // MARK: - Realm Configuration
    static func initializeRealm(name: String = "followUpRealm") -> Realm? {
        // Get the document directory and create a file with the passed name
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let realmFileURL = documentDirectory?.appendingPathComponent("\(name).realm")
        let config = Realm.Configuration(
            fileURL: realmFileURL,
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    Log.info("Running migration to schema v2, adding contactListGrouping.")
                    migration.enumerateObjects(ofType: FollowUpSettings.className()) { oldObject, newObject in
                        newObject?["contactListGrouping"] = FollowUpSettings.ContactListGrouping.dayMonthYear.rawValue
                    }
                }
                
                if oldSchemaVersion < 4 {
                    Log.info("Running migration to schema v4. Adding 'tags' property.")
                    migration.enumerateObjects(ofType: Contact.className()) { oldObject, newObject in
                        newObject?["tags"] = RealmSwift.List<Tag>()
                    }
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        do {
            return try Realm()
        } catch {
            print("Could not open realm: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetches any existing FollowUpStores from Realm. If one does not exist, then one is created and returned.
//    func fetchFollowUpStoreFromRealm() -> FollowUpStore {
//
//        guard let realm = self.realm else {
//            assertionFailurePreviewSafe("Could not initialise FollowUpStore as Realm is nil.")
//            return .init()
//        }
//
//        if let followUpStore = realm.objects(FollowUpStore.self).first {
//            return followUpStore
//        } else {
//            let followUpStore: FollowUpStore = .init()
//            do {
//                try realm.write {
//                    realm.add(followUpStore)
//                }
//            } catch {
//                print("Could not add FollowUpStore to realm: \(error.localizedDescription)")
//            }
//            return followUpStore
//        }
//    }
    
    // Notification Configuration
    func configureNotifications() {
        self.notificationManager.requestNotificationAuthorization()
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Constant.appIdentifier,
            using: nil,
            launchHandler: { task in
                guard let appRefreshTask = task as? BGAppRefreshTask else { return }
                self.handleScheduledNotificationsBackgroundTask(appRefreshTask)
            }
        )
        
        self.scheduleBackgroundTaskForConfiguringNotifications(onDay: .now)
        
        self.scheduleFollowUpReminderNotification()
    }
    
    private func scheduleBackgroundTaskForConfiguringNotifications(onDay date: Date?) {
        let date = date ?? .now

        let backgroundTaskRequest = BGAppRefreshTaskRequest(identifier: Constant.appIdentifier)
        
        // Schedule the background task 30 minutes before the notification should be sheduled to the user.
        let backgroundTaskDate = date
            .setting(.hour, to: Constant.Notification.defaultNotificationTriggerHour - 1)?
            .setting(.minute, to: 30)
        
        backgroundTaskRequest.earliestBeginDate = backgroundTaskDate
        
        // Schedule the task on a background queue as submission is a blocking procedure.
        DispatchQueue.global(qos: .background).async {
            do {
                try BGTaskScheduler.shared.submit(backgroundTaskRequest)
                print("Scheduled notification configuration background task for \(backgroundTaskDate?.description ?? "unknown date")")
            } catch {
                print("Could not submit background task to schedule notifications. \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleFollowUpReminderNotification() {
        self.notificationManager.scheduleNotification(
            forNumberOfAddedContacts: self.store.contacts(
                metWithinTimeframe: .today
                
            ).count,
            withConfiguration: .default
        )
    }
    
    /// Contains the logic associated with a request to sechedule notifications while the app is running in the background.
    private func handleScheduledNotificationsBackgroundTask(_ task: BGAppRefreshTask) {
        task.expirationHandler = {
            print("Could not register notifications.")
        }
        
        // Clear current notifications.
        self.notificationManager.clearScheduledNotifications()
        
        // Re-register notifications.
        self.scheduleFollowUpReminderNotification()
        
        // Schedule a background task for tomorrow, at the same time.
        self.scheduleBackgroundTaskForConfiguringNotifications(onDay: Date().adding(1, to: .day))
        
        task.setTaskCompleted(success: true)
    }

}
