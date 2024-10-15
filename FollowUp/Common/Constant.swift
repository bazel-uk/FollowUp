//
//  Constant.swift
//  FollowUp
//
//  Created by Aaron Baw on 09/10/2021.
//

import Foundation
import CoreGraphics
import SwiftUI
import RealmSwift

enum Constant {
    
    // MARK: - App Identifier
    static let appIdentifier: String = "com.bazel.followup"

    // MARK: - Padding
    static let verticalPadding: CGFloat = 10.0

    // MARK: - Misc
    static let cornerRadius: CGFloat = 15.0
    static let buttonCornerRadius: CGFloat = 8.0
    static let borderedButtonPadding: CGFloat = 15.0

    // MARK: - Date Formatting
    static let relativeDateTimeFormatter: RelativeDateTimeFormatter = .init()

    // MARK: - Round Badge
    enum ContactBadge {
        
        enum Size {
            case small
            case large
            
            var width: CGFloat {
                switch self {
                case .small: return 23
                case .large: return 50
                }
            }
            
            var padding: CGFloat {
                switch self {
                case .small: return 10.0
                case .large: return 20.0
                }
            }
        }

    }

    // MARK: - Icons
    enum Icon: String, PersistableEnum {
        case bolt = "bolt.fill"
        case chatBubbles = "bubble.left.and.bubble.right.fill"
        case chatWithElipses = "ellipsis.message.fill"
        case chatWithWaveform = "message.and.waveform.fill"
        case checkmark = "checkmark"
        case chevronRight = "chevron.right"
        case clock = "clock.arrow.circlepath"
        case close = "xmark.circle.fill"
        case closeOutline = "xmark"
        case email = "envelope.fill"
        case minus = "minus"
        case partyPopper = "party.popper.fill"
        case pencil = "pencil"
        case personWithAtSymbol = "person.crop.square.filled.and.at.rectangle.fill"
        case personWithCheckmark = "person.crop.circle.fill.badge.checkmark"
        case personWithClock = "person.badge.clock.fill"
        case personWithDescription = "person.text.rectangle.fill"
        case phone = "phone.fill"
        case plus = "plus"
        case settings = "gearshape.fill"
        case sms = "bubble.left.fill"
        case star = "star.fill"
        case starWithText = "text.badge.star"
        case slashedStar = "star.slash.fill"
        case target = "target"
        case thumbsUp = "hand.thumbsup.fill"
        case trash = "trash.fill"
        case whatsApp = "whatsAppIcon"

        case arrowCirclePath = "arrow.triangle.2.circlepath"
        case lock = "lock.fill"
        case lockWithExclamationMark = "lock.trianglebadge.exclamationmark"
        
        static let mediumSize: CGFloat = 30.0

        enum Kind {
            case asset
            case sfSymbol
        }

        var kind: Kind {
            switch self {
            case .bolt, .chatBubbles, .chatWithElipses, .chatWithWaveform, .checkmark, .chevronRight, .clock, .closeOutline, .close, .email, .minus, .partyPopper, .pencil, .personWithAtSymbol, .personWithCheckmark, .personWithClock, .personWithDescription, .phone, .plus, .settings, .sms, .star, .starWithText, .slashedStar, .target, .thumbsUp, .trash, .arrowCirclePath, .lock, .lockWithExclamationMark: return .sfSymbol
            case .whatsApp: return .asset
            }
        }
    }

    // MARK: - Contact Card
    enum ContactCard {
        static let minSize: CGFloat = 200.0
    }

    // MARK: - Contact Sheet
    enum ContactSheet {
        static let verticalSpacing: CGFloat = 10.0
        static let maxHeight: CGFloat = 400.0
        static let noHighlightsViewMaxContentWidth: CGFloat = 250.0
        static let noteViewMaxHeight: CGFloat = 150.0
        static let bottomPaddingForFollowUpDetails: CGFloat = 120.0
    }
    
    // MARK: - Hero Message
    enum HeroMessage {
        static let verticalSpacing: CGFloat = 10.0
        static let maxContentWidth: CGFloat = 250.0
    }

    // MARK: - Conversation Action Button
    enum ConversationActionButton {
        static let maxWidth: CGFloat = 200.0
    }
    
    // MARK: - Circular Loading Spiner
    enum CircularLoadingSpinner {
        static let defaultSize: CGFloat = 25.0
        static let defaultLineWidth: CGFloat = 5.0
        static let defaultBackgroundCircleOpacity: CGFloat = 0.50
        static let defaultColour: Color = .blue
    }
    
    // MARK: - Tags
    enum Tag {
        static let horiztontalPadding: CGFloat = 10.0
        static let verticalPadding: CGFloat = 5.0
        static let cornerRadius: CGFloat = 5.0
    }

    // MARK: - Keys
    enum Key {
        static let followUpStore: String = "storage.FollowUpStore"

        enum FollowUpStore {
            static let contacts: String = "storage.FollowUpStore.contacts"
            static let contactDictionary: String = "storage.FollowUpStore.contactDictionary"
        }
    }
    
    // MARK: - Contact List
    enum ContactList {
        static let maxContactsForNonLazyVStack: Int = 20
        static let verticalSpacing: CGFloat = 20.0
        static let newContactsBadgeSize: CGFloat = 22.0
    }
    
    // MARK: - Search
    enum Search {
        static let contactSearchDebounce: RunLoop.SchedulerTimeType.Stride = 0.5
        static let tagSearchDebounce: RunLoop.SchedulerTimeType.Stride = 0.1
        static let maxNumberOfDisplayedSearchTagSuggestions: Int = 9
        static let suggestedTagViewTopPadding: CGFloat = 7.0
    }
    
    
    // MARK: - Secrets
    enum Secrets {
        static let openAIUserDefaultsKey: String = "openAIKey"
    }
    
    // MARK: - Conversation Starter
    enum ConversationStarter {
        
        enum Token: String, CaseIterable {
            case name = "<NAME>"
            
            var title: String {
                switch self {
                case .name: return "Name"
                }
            }
        }
        
        static let defaultMaxTokenGenerationLength: Int = 1000
    }
    
    // MARK: - Notifications
    enum Notification {
        static let defaultNotificationTriggerHour: Int = 9
        static let defaultNotificationTriggerMinute: Int = 0
    }
    
    // MARK: - Processing
    enum Processing {
        /// Determines the total number of contacts that will be processed within a background task. Used to prevent background tasks from failing when users have very large contact lists.
        static let numberOfContactsToProcessInBackground = 100
        static let followUpRemindersTaskIdentifier = "\(Constant.appIdentifier).followupreminders"
    }
    
    // MARK: - Frequency Defaults
    /// Frequency defaults are used to calculate the 'outOfTouch' delta (i.e., how long it has been since a contact should have been contacted). If a contact is to be followed up with 'every day', the _time_ of that day should be consistent across all contacts (e.g. 12:00pm). If a user determines a contact should be followed up with every day, then the first reminder will come the next day at 12:00pm (or the hour that has been set in 'dailyFollowUpHour').
    enum FollowUpFrequency {
        
        static let dailyFollowUpHour: DateComponents = {
            let locale = Locale(identifier: "en_US")
            var calendar = Calendar(identifier: .gregorian)
            let components = DateComponents(hour: 12)
            return components
        }()
        
        // By default, we use '2', i.e. 'Monday' as the weeklyFollowUpDay. In most Gregorian calendars, this is the second day of the week, for the other half of the world, it is actually the first day of the week.
        // TODO: - Ensure that this is consistent across Locales.
        static let weeklyFollowUpDay: DateComponents = {
            var components = Self.dailyFollowUpHour
            components.weekday = 2
            return components
        }()
        
        static let monthlyFollowUpDay: DateComponents = {
            var components = Self.weeklyFollowUpDay
            components.weekOfMonth = 1
            return components
        }()
        
    }
    
}
