//
//  Contact.swift
//  FollowUp
//
//  Created by Aaron Baw on 09/10/2021.
//

import AddressBook
import Contacts
import Foundation
import RealmSwift
import UIKit

protocol Contactable: Object, Identifiable {
    var id: ContactID { get }
    var name: String { get }
    var phoneNumber: PhoneNumber? { get }
    var email: String? { get }
    var thumbnailImage: UIImage? { get }
    var note: String? { get set }
    var tags: RealmSwift.List<Tag> { get set }
    var followUps: Int { get set }
    var createDate: Date { get set }
    var highlighted: Bool { get }
    var containedInFollowUps: Bool { get }
    var followUpFrequency: FollowUpFrequency? { get set }

    /// New contacts younger than one week, and have not been interacted with.
    var isNew: Bool { get }

    // MARK: - Interaction Indicators
    var lastFollowedUp: Date? { get set }
    var hasBeenFollowedUpToday: Bool { get }
    var lastInteractedWith: Date? { get set }
    var hasInteractedWithToday: Bool { get }
    var nextFollowUpDate: Date? { get }
    var daysUntilNextFollowUp: Int? { get }
}

// MARK: - Default Implementations
extension Contactable {
    var isNew: Bool {
        self.relativeDateGrouping <= .week && lastInteractedWith == nil
    }
    
    var nextFollowUpDate: Date? {
        guard let lastFollowedUp = lastFollowedUp else { return nil }
        return self.followUpFrequency?.nextFollowUpDate(forDate: lastFollowedUp)
    }
    
    var daysUntilNextFollowUp: Int? {
        guard let nextFollowUpDate = nextFollowUpDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: nextFollowUpDate).day
    }
    
    /// Creates a hash value of the contact which does _not_ contain the 'note', 'id', or 'createDate' properties. This is used for merging.
    func mergeableHashValue() -> Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(phoneNumber?.description)
        hasher.combine(email)
        return hasher.finalize()
    }
}

class Contact: Object, ObjectKeyIdentifiable, Contactable, Identifiable {
    
    
    // MARK: - Enums
    enum ImageFormat {
        case thumbnail
        case full
    }

    // MARK: - Stored Properties
//    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted(primaryKey: true) var id: ContactID
    @Persisted var name: String
    @Persisted var phoneNumber: PhoneNumber?
    @Persisted var _thumbnailImageData: Data?
    @Persisted var email: String?
    @Persisted var createDate: Date
    @Persisted var note: String?

    
    // MARK: - Protocol Conformance
    var thumbnailImage: UIImage? {
        get {
            guard let data = self._thumbnailImageData else {
                return nil
            }
            return UIImage(data: data)

        }
        set {
            self._thumbnailImageData = newValue?.jpegData(compressionQuality: 1)
        }
    }
    
    // MARK: - Interactive Properties
    @Persisted var tags: RealmSwift.List<Tag> { didSet { lastInteractedWith = .now } }
    @Persisted var followUps: Int = 0 { didSet { lastFollowedUp = .now } }
    @Persisted var lastFollowedUp: Date? { didSet { lastInteractedWith = .now } }
    @Persisted var highlighted: Bool = false { didSet { lastInteractedWith = .now } }
    @Persisted var followUpFrequency: FollowUpFrequency? { didSet { lastInteractedWith = .now } }
    
    // TODO: - Ensure that this is reworked to act as a computed property that depends on the 'followUpFrequency' object.
    @Persisted var containedInFollowUps: Bool = false { didSet { lastInteractedWith = .now } }

    // MARK: - Interaction Indicators
    @Persisted var lastInteractedWith: Date?
    
    convenience init(
        contactID: ContactID = UUID().uuidString,
        name: String,
        phoneNumber: PhoneNumber?,
        email: String?,
        thumbnailImage: UIImage?,
        note: String? = nil,
        followUps: Int = 0,
        createDate: Date,
        lastFollowedUp: Date? = nil,
        highlighted: Bool = false,
        containedInFollowUps: Bool = false,
        lastInteractedWith: Date? = nil
    ) {
        self.init()
        self.id = contactID
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.thumbnailImage = thumbnailImage
        self.note = note
        self.followUps = followUps
        self.createDate = createDate
        self.lastFollowedUp = lastFollowedUp
        self.highlighted = highlighted
        self.containedInFollowUps = containedInFollowUps
        self.lastInteractedWith = lastInteractedWith
    }
    
    // MARK: - Codable Conformance
//    enum CodingKeys: CodingKey {
//        case id, name, phoneNumber, thumbnailImage, note, followUps, createDate, lastFollowedUp, highlighted, containedInFollowUps, lastInteractedWith
//    }
//
//    required init(from decoder: Decoder) throws {
//        self.init()
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(ObjectId.self, forKey: .id)
//        self.name = try container.decode(String.self, forKey: .name)
//        self.phoneNumber = try container.decodeIfPresent(PhoneNumber.self, forKey: .phoneNumber)
//        self.thumbnailImage = try container.decodeIfPresent(Data.self, forKey: .thumbnailImage)?.uiImage
//        self.note = try container.decodeIfPresent(String.self, forKey: .note)
//        self.followUps = try container.decode(Int.self, forKey: .followUps)
//        self.createDate = try container.decode(Date.self, forKey: .createDate)
//        self.lastFollowedUp = try container.decodeIfPresent(Date.self, forKey: .lastFollowedUp)
//        self.highlighted = try container.decode(Bool.self, forKey: .highlighted)
//        self.containedInFollowUps = try container.decode(Bool.self, forKey: .containedInFollowUps)
//        self.lastInteractedWith = try container.decodeIfPresent(Date.self, forKey: .lastInteractedWith)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(name, forKey: .name)
//        try container.encode(phoneNumber, forKey: .phoneNumber)
//        try container.encodeIfPresent(thumbnailImage?.pngData(), forKey: .thumbnailImage)
//        try container.encode(note, forKey: .note)
//        try container.encode(followUps, forKey: .followUps)
//        try container.encode(createDate, forKey: .createDate)
//        try container.encode(lastFollowedUp, forKey: .lastFollowedUp)
//        try container.encode(highlighted, forKey: .highlighted)
//        try container.encode(containedInFollowUps, forKey: .containedInFollowUps)
//        try container.encode(lastInteractedWith, forKey: .lastInteractedWith)
//    }

    
}

// MARK: - Convenience Initialisers and Conversions
extension Contact {
    convenience init(from contact: CNContact){
        self.init(
            contactID: contact.identifier,
            name: [
                contact.givenName,
                contact.middleName.isEmpty ? nil : contact.middleName,
                contact.familyName
            ].compactMap( { $0 }).joined(separator: " ").trimmingWhitespace(),
            phoneNumber: .init(contact.phoneNumbers.first),
            email: nil,
            thumbnailImage: (contact.thumbnailImageData ?? contact.thumbnailImageData)?.uiImage,
            note: contact.note,
            followUps: 0,
            // ⚠️ TODO: Update this to use the provided dates from CNContact.
            createDate: Date(),
            lastFollowedUp: nil,
            highlighted: false,
            containedInFollowUps: false,
            lastInteractedWith: nil
        )
    }

    convenience init(from contact: any Contactable){
        self.init(
            contactID: contact.id,
            name: contact.name,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            thumbnailImage: contact.thumbnailImage,
            note: contact.note,
            followUps: contact.followUps,
            createDate: contact.createDate,
            lastFollowedUp: contact.lastFollowedUp,
            highlighted: contact.highlighted,
            containedInFollowUps: contact.containedInFollowUps,
            lastInteractedWith: contact.lastInteractedWith
        )
    }
}

// MARK: - Conversion to Concrete type Convenience
extension Contactable {
    var concrete: Contact {
        (self as? Contact) ?? Contact.init(from: self)
    }
}

// MARK: - Grouping Extension
extension Contactable {
    
    var dayMonthYearDateGrouping: Grouping {
        isNew ? .new : .concreteDate(grouping: .dayMonthYear(forDate: self.createDate))
    }
    
    var monthYearDateGrouping: Grouping {
        isNew ? .new : .concreteDate(grouping: .monthYear(forDate: self.createDate))
    }

    var relativeDateGrouping: RelativeDateGrouping {
        RelativeDateGrouping.allCases.first(where: { grouping in
            grouping.dateInterval?.contains(self.createDate) == true
        }) ?? .beforeLastMonth
    }

    var newOrRelativeDateGrouping: Grouping {
        isNew ? .new : .relativeDate(grouping: relativeDateGrouping)
    }

}

// MARK: - Computed Properties
extension Contactable {
    var firstName: String { name.split(separator: " ").first?.capitalized ?? name }

    var lastName: String { name.split(separator: " ").last?.capitalized ?? "" }

    var initials: String {
        (firstName.first?.uppercased() ?? "") + (lastName.first?.uppercased() ?? "")
    }

    var hasBeenFollowedUpToday: Bool {
        guard let lastFollowedUpDate = self.lastFollowedUp else { return false}
        return Calendar.current.isDateInToday(lastFollowedUpDate)
    }

    var hasInteractedWithToday: Bool {
        guard let lastInteractionDate = self.lastInteractedWith else { return false }
        return Calendar.current.isDateInToday(lastInteractionDate)
    }

    var sheet: ContactSheet {
        .init(contactID: self.id)
    }
}

// MARK: - Static Property Extension
extension Contact {
    static var unknown: Contact {
        .init(
            name: "Unknown",
            phoneNumber: .init(from: "+350 54022819", withLabel: "Gib Number"),
            email: nil,
            thumbnailImage: nil,
            followUps: 2,
            createDate: .distantPast,
            lastFollowedUp: Date()
        )
    }
}
