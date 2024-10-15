//
//  Localizer.swift
//  FollowUp
//
//  Created by Aaron Baw on 20/11/2022.
//

import Foundation

struct Localizer {
    enum Notification {
        
        // MARK: - Title
        static let title: String = "FollowUp"
        
        // MARK: - Template Strings
        static let numberOfPeopleMetBodyTemplateString: String = "You met \(Self.numPeopleReplacementToken) \(Self.timeFrameReplacementToken). Would you like to follow up?"
        static let recentlyAddedNamesTemplateString: String = "You recently met \(Self.namesReplacementToken). Follow up?"
        static let fallbackTemplateString: String = "Would you like to follow up?" // This is used when, for e.g. no new contacts have been recently added.
        
        // MARK: - Tokens
        static let numPeopleReplacementToken: String = "<%NUM_PEOPLE%>"
        static let timeFrameReplacementToken: String = "<%DATE_UNIT%>"
        static let namesReplacementToken: String = "<%NAMES%>"
        
        // MARK: - Functions
        static func body(
            withNumberOfPeople numberOfPeople: Int,
            withinTimeFrame timeFrame: RelativeDateGrouping
        ) -> String {
            let numberOfPeopleString = numberOfPeople >= Constant.Processing.numberOfContactsToProcessInBackground ? "over \(numberOfPeople)" : "\(numberOfPeople)"
            let stringWithNumPeople = self.numberOfPeopleMetBodyTemplateString.replacingOccurrences(of: self.numPeopleReplacementToken, with: "\(numberOfPeopleString) \(numberOfPeople == 1 ? "person" : "people")")
            let stringWithNumPeopleAndTimeFrame = stringWithNumPeople.replacingOccurrences(of: self.timeFrameReplacementToken, with: timeFrame.title.lowercased())
            
            return stringWithNumPeopleAndTimeFrame
        }
        
        static func body(
            withRecentlyAddedContactNames names: [String]
        ) -> String {
            let names = names.map { $0.trimmingWhitespace() }
            guard names.count > 0 else { return self.fallbackTemplateString }
            
            let namesString: String
            if names.count == 1 {
                namesString = names.first ?? "someone new"
            } else {
                namesString = names.prefix(2).joined(separator: ", ") + (names.count > 2 ? " and more" : "")
            }
            
            let string = self.recentlyAddedNamesTemplateString.replacingOccurrences(of: self.namesReplacementToken, with: namesString)
            
            return string
        }
    }
}
