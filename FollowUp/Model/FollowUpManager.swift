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
    
    /// Error to be displayed to the user.
    @Published var error: FollowUpError?

    var contactsInteractor: ContactsInteracting
    private var subscriptions: Set<AnyCancellable> = .init()
    var notificationManager: NotificationManaging
    
    private var locationManager: LocationManaging?
    
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
        
        // Initialize LocationManager and start monitoring
        self.locationManager = LocationManager(followUpManager: self)
        self.locationManager?.startMonitoring()
    }

    // MARK: - Methods
    private func subscribeForNewContacts() {
        self.contactsInteractor
            .contactsPublisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        return
                    case let .failure(error):
                        self.error = error
                    }
                },
                receiveValue: { contactSignal in
                    switch contactSignal {
                    case let .overwrite(newContacts):
                        self.store.updateWithFetchedContacts(newContacts)
                    case let .updateAndMerge(contact):
                        self.store.updateAndMerge(contact: contact)
                    }
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
            schemaVersion: 6,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    Log.info("Running migration to schema v2, adding contactListGrouping.")
                    migration.enumerateObjects(ofType: FollowUpSettings.className()) { oldObject, newObject in
                        newObject?["contactListGrouping"] = FollowUpSettings.ContactListGrouping.dayMonthYear.rawValue
                    }
                    Log.info("Migration complete.")
                }
                
                if oldSchemaVersion < 4 {
                    Log.info("Running migration to schema v4. Adding 'tags' property.")
                    migration.enumerateObjects(ofType: Contact.className()) { oldObject, newObject in
                        newObject?["tags"] = RealmSwift.List<Tag>()
                    }
                }

                if oldSchemaVersion < 5 {
                    Log.info("Running migration to schema V5.")
                    migration.enumerateObjects(ofType: FollowUpSettings.className(), { oldObject, newObject in
                        newObject?["followUpRemindersActive"] = false
                    })
                    Log.info("Migration complete.")
                }
                
                if oldSchemaVersion < 6 {
                    Log.info("Running migration to schema v6. Adding 'followUpFrequency' property.")
                    migration.enumerateObjects(ofType: Contact.className(), {oldObject, newObject in
                        newObject?["followUpFrequency"] = FollowUpFrequency.daily
                    })
                }
                
            }
        )
        
        // We set the default configuration so that we can open up multiple Realm instances with the same configuration.
        Realm.Configuration.defaultConfiguration = config
        
        do {
            return try Realm()
        } catch {
            Log.error("Could not open realm: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    /// Uses significant location updates to periodically check for new contacts and schedule reminders to follow up.
    func configureNotifications() {
        
            DispatchQueue.main.async {
                
                if self.store.settings.followUpRemindersActive {
                    
                    // Check if we have the right authorisation for notifications and local updates.
                    self.notificationManager.requestNotificationAuthorization()
                    self.locationManager?.requestAuthorisation()
                    
                                        
                    self.scheduleBackgroundTaskForConfiguringNotifications(
                        onDay: .now.setting(
                            .hour,
                            to: Constant.Notification.defaultNotificationTriggerHour
                        )?.setting(.minute, to: 0)?.setting(.second, to: 0)
                    )
                    
                }
            }
            
        
    }
    
    // Legacy Notification Configuration
//    func configureNotifications() {
//        BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { requests in
//            
//            DispatchQueue.main.async {
//                
//                if self.store.settings.followUpRemindersActive {
//                    
//                    // Check if we have the right authorisation.
//                    self.notificationManager.requestNotificationAuthorization()
//                    
//                    // Check to see if any background tasks are scheduled.
//                    guard !requests.map(\.identifier).contains(Constant.Processing.followUpRemindersTaskIdentifier)
//                    else {
//                        Log.info("Background task already scheduled for follow up reminders.")
//                        return
//                    }
//                    
//                    Log.info("No background tasks found for follow up reminders. Scheduling now.")
//                    
//                    self.scheduleBackgroundTaskForConfiguringNotifications(
//                        onDay: .now.setting(
//                            .hour,
//                            to: Constant.Notification.defaultNotificationTriggerHour
//                        )?.setting(.minute, to: 0)?.setting(.second, to: 0)
//                    )
//                    
//                } else {
//                    // Remove all pending tasks.
//                    Log.info("Removing \(requests.count) background tasks for follow up reminders.")
//                    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Constant.Processing.followUpRemindersTaskIdentifier)
//                }
//            }
//            
//        })
//        
//    }
    
    private func scheduleBackgroundTaskForConfiguringNotifications(onDay date: Date?) {
        let date = date ?? .now

        let backgroundTaskRequest = BGAppRefreshTaskRequest(identifier: Constant.Processing.followUpRemindersTaskIdentifier)
        
        // Schedule the background task 30 minutes before the notification should be sheduled to the user.
        let backgroundTaskDate = date
            .setting(.hour, to: Constant.Notification.defaultNotificationTriggerHour - 1)?
            .setting(.minute, to: 30)
        
        backgroundTaskRequest.earliestBeginDate = backgroundTaskDate
        
        // Schedule the task on a background queue as submission is a blocking procedure.
        DispatchQueue.global(qos: .background).async {
            do {
                try BGTaskScheduler.shared.submit(backgroundTaskRequest)
                Log.info("Scheduled notification configuration background task for \(backgroundTaskDate?.description ?? "unknown date")")
            } catch {
                Log.error("Could not submit background task to schedule notifications. \(error.localizedDescription)")
            }
        }
    }
    
    func calculateNewlyMetContactsAndScheduleFollowUpReminderNotification() {
        self.contactsInteractor.fetchRecentlyAddedContacts(completion: { newContacts in
            
            // Before scheduling a new notification, we must clear the last one.
            Log.info("Clearing previously scheduled notifications.")
            self.notificationManager.clearScheduledNotifications()
            
            Log.info("Detected \(newContacts.count) recently added contacts. Reporting attempting to schedule notification.")
            self.notificationManager.scheduleRecentlyAddedNamesNotification(
                forRecentlyAddedContacts: newContacts,
                withConfiguration:
                        .init(
                            trigger: .tomorrowAt(
                                hour: Constant.Notification.defaultNotificationTriggerHour,
                                minute: Constant.Notification.defaultNotificationTriggerMinute
                            )
                        )
                )
        })
        
//        self.store.numberOfContacts(.thatAreNew) { numberOfContacts in
//            guard let numberOfContacts = numberOfContacts else {
//                Log.error("Unable to determine number of contacts met within specified timeframe.")
//                return
//            }
//            Log.info("Detected \(numberOfContacts) met today. Reporting attempting to schedule notification.")
//            self.notificationManager.scheduleNotification(
//                forNumberOfAddedContacts: numberOfContacts,
//                withConfiguration: .init(trigger: .now)
//            )
//        }
    }
    
    /// Contains the logic associated with a request to sechedule notifications while the app is running in the background.
    public func handleScheduledNotificationsBackgroundTask(_ task: BGAppRefreshTask?) {
        
        Log.info("Executing background task: \(task?.description ?? "Unknown task")")
        
        task?.expirationHandler = {
            Log.error("Could not register notifications.")
        }
                 
         // Clear current notifications.
         self.notificationManager.clearScheduledNotifications()
         
         // Re-register notifications.
         self.calculateNewlyMetContactsAndScheduleFollowUpReminderNotification()
         
         // Schedule a background task for tomorrow, at the same time.
         self.scheduleBackgroundTaskForConfiguringNotifications(onDay: Date().adding(1, to: .day))
         
         task?.setTaskCompleted(success: true)
    }

}
