//
//  ConversationStarterTemplate.swift
//  FollowUp
//
//  Created by Aaron Baw on 26/01/2023.
//

import Foundation
import RealmSwift

// MARK: -
protocol ConversationStarting: Codable, Equatable, Hashable {
    
    var title: String { get }
    var kind: ConversationStarterKind { get }
    
    var template: String? { get set }
    var prompt: String? { get set }
    var context: String? { get set }

    func generateFormattedText(
        withContact contact: any Contactable
    ) async -> Result<String, Error>
    
    func generateFormattedText(
        withContact contact: any Contactable,
        completion: @escaping ((Result<String, Error>) -> Void)
    )
}

// MARK: - Equality Extension
extension ConversationStarting {
    func equals(_ other: any ConversationStarting) -> Bool {
        if let thisStarter = self as? StandardConversationStarter, let otherStarter = other as? StandardConversationStarter {
            return thisStarter ==  otherStarter
        }
        
        if let thisStarter = self as? IntelligentConversationStarter, let otherStarter = other as? IntelligentConversationStarter {
            return thisStarter == otherStarter
        }
        return false
    }
}

// MARK: -
enum ConversationStarterKind: Codable, Hashable, Equatable, CaseIterable {
    case standard
    case intelligent
    
    var buttonTitle: String {
        switch self {
        case .standard: return "Standard"
        case .intelligent: return "Intelligent"
        }
    }
    
    var icon: Constant.Icon {
        switch self {
        case .intelligent: return .chatWithWaveform
        case .standard: return .chatBubbles
        }
    }
}

/// Standard conversation starter which uses a template message and replaces key words with their respective token values, such as `<NAME>`.
struct StandardConversationStarter: ConversationStarting {
    
    // MARK: - Stored Properties
    var template: String?
    let kind: ConversationStarterKind = .standard

    // Unused properties.
    var prompt: String? = nil
    var context: String? = nil
    
    // MARK: - Computed Properties
    var title: String { self.template ?? "" }
    
    // MARK: - Errors
    enum StandardConversationStarterError: Error {
        case couldNotUnwrapTemplate
    }

    // MARK: - Methods
    func generateFormattedText(withContact contact: any Contactable) async -> Result<String, Error> {
        guard let template = template else { return .failure(StandardConversationStarterError.couldNotUnwrapTemplate)}
        return .success(template.replacingOccurrences(of: "<NAME>", with: contact.firstName))
    }
    
    func generateFormattedText(withContact contact: any Contactable, completion: @escaping ((Result<String, Error>) -> Void)) {
        guard let template = template else {
            return completion(.failure(StandardConversationStarterError.couldNotUnwrapTemplate))
        }
        return completion(.success(template.replacingOccurrences(of: "<NAME>", with: contact.firstName)))
    }
}

/// Uses AI (ChatGPT) to generate customised conversation starter messages.
struct IntelligentConversationStarter: ConversationStarting {
    
    
    // MARK: - Stored Properties
    var prompt: String?
    var context: String?
    let kind: ConversationStarterKind = .intelligent
    
    // Unused properties.
    var template: String? = nil
    
    // MARK: - Computed Properties
    var title: String { self.prompt ?? "" }
    
    // MARK: - Errors
    enum IntelligentConversationStarterError: Error {
        case couldNotGenerate(Error)
        case couldNotUnwrapPrompt
    }

    // MARK: - Methods
    func generateFormattedText(withContact contact: any Contactable) async -> Result<String, Error> {
        guard let prompt = prompt else { return .failure(IntelligentConversationStarterError.couldNotUnwrapPrompt) }
        let requestString = self.constructChatGPTRequestString(for: contact, withPrompt: prompt, context: context)
        do {
            let result = try await Networking.sendRequestToGPT3(prompt: requestString).value
            return .success(result)
        } catch {
            return .failure(IntelligentConversationStarterError.couldNotGenerate(error))
        }
    }
    
    func generateFormattedText(withContact contact: any Contactable, completion: @escaping ((Result<String, Error>) -> Void)) {
        guard let prompt = prompt else { return completion(.failure(IntelligentConversationStarterError.couldNotUnwrapPrompt)) }
        let requestString = self.constructChatGPTRequestString(for: contact, withPrompt: prompt, context: context)
        Networking.sendRequestToGPT3(prompt: requestString, completion: completion)
    }
    
    private func constructChatGPTRequestString(for contact: any Contactable, withPrompt prompt: String, context: String?) -> String {
        
        var requestStringComponents: [String] = []
        
        requestStringComponents.append("I have a contact called \(contact.name).")
        
       if let contactNote: String = contact.note {
            requestStringComponents.append("Here's a description of the contact: \"\(contactNote)\"")
        }
        
        if let context = context {
            requestStringComponents.append("For some added context, \(context).")
        }
        
        requestStringComponents.append(prompt)
        
        return String(requestStringComponents.joined(separator: "\n\n"))
    }

}

// MARK: -
struct ConversationStarterTemplate: Codable, Hashable, Identifiable, CustomPersistable {
    
    // TODO: Need to completely fill this out.
    static func == (lhs: ConversationStarterTemplate, rhs: ConversationStarterTemplate) -> Bool {
        return  lhs.starter.equals(rhs.starter) &&
        lhs.title == rhs.title &&
        lhs.kind == rhs.kind &&
        lhs.id == rhs.id &&
        lhs.label == rhs.label &&
        lhs.platform == rhs.platform
    }
    
    typealias PersistedType = Data
    
    enum Platform: Codable, Hashable, Equatable {
        case whatsApp

        var icon: Constant.Icon {
            switch self {
            case .whatsApp: return .whatsApp
            }
        }
    }
        
    var label: String?
    var starter: any ConversationStarting
    var platform: Platform
    var id: String

    var kind: ConversationStarterKind {
        didSet {
            guard self.kind != self.starter.kind else { return }
            switch self.kind {
            case .standard:
                self.starter = StandardConversationStarter(template: "")
            case .intelligent:
                self.starter = IntelligentConversationStarter(prompt: "")
            }
        }
    }
    
    var persistableValue: Data {
        (try? JSONEncoder().encode(self)) ?? .init()
    }
    
    // MARK: - Computed Properties
    var title: String {
        guard let label = label, !label.isEmpty else {
            return self.starter.title
        }
        return label
    }
    
    // MARK: - Initialisers
    init(persistedValue: Data) {
        let decodedObject = try? JSONDecoder().decode(Self.self, from: persistedValue)
        self = decodedObject ?? .init(template: "", platform: .whatsApp)
    }
    
    /// Create a standard conversation starter.
    init(
        label: String? = nil,
        template: String,
        platform: Platform,
        id: String? = nil
    ) {
        self.kind = .standard
        self.starter = StandardConversationStarter(template: template)
        self.label = label
        self.platform = platform
        self.id = id
    }
    
    /// Create an intelligent conversation starter
    init(
        label: String? = nil,
        prompt: String,
        context: String?,
        platform: Platform,
        id: String = UUID().uuidString
    ) {
        self.kind = .intelligent
        self.starter = IntelligentConversationStarter(prompt: prompt, context: context)
        self.label = label
        self.platform = platform
        self.id = id ?? UUID().uuidString
    }
    
    // MARK: - Methods
    
    /// Uses the current template to create a conversation starter button action given the platform and contact.
    func buttonAction(
        contact: any Contactable
    ) throws -> ButtonAction? {
        switch self.platform {
        case .whatsApp:
            guard let number = contact.phoneNumber else { return nil }
            return .whatsApp(number: number, generateText: { completion in
                let contactCopy = contact.concrete
                self.starter.generateFormattedText(withContact: contactCopy) { result in
                    DispatchQueue.main.async {
                        completion(result)
                    }
                }
            })
        }
    }
    
    enum CodingKeys: CodingKey {
        case label
        case kind
        case starter
        case platform
        case id
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.label, forKey: .label)
        try container.encode(self.platform, forKey: .platform)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.starter, forKey: .starter)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.platform = try container.decode(Platform.self, forKey: .platform)
        self.id = try container.decode(String.self, forKey: .id)

        // We first determine the "Kind" of Conversation Starter so that we know how to decode the object, since the 'self.starter' property is a protocol. This allows us to know which concrete structure to decode.
        let kind = try container.decode(ConversationStarterKind.self, forKey: .kind)
        self.kind = kind
        
        switch kind {
        case .standard: self.starter = try container.decode(StandardConversationStarter.self, forKey: .starter)
        case .intelligent: self.starter = try container.decode(IntelligentConversationStarter.self, forKey: .starter)
        }
    }
}

extension ConversationStarterTemplate {
    enum StarterGenerationError: Error {
        case couldNotGenerate(Error)
    }
}

// MARK: - Default Values
extension ConversationStarterTemplate {
    static var arrangeForCoffee: ConversationStarterTemplate {
        .init(label: "Arrange for coffee", template: "Hey <NAME>! How are you? I was wondering if you'd be free for a coffee this week?", platform: .whatsApp)
    }
    
    static var howAreYou: ConversationStarterTemplate {
        .init(label: "How are you?", template: "Hey <NAME>! How are you?", platform: .whatsApp)
    }
    
    static var examples: [ConversationStarterTemplate] = [
        .arrangeForCoffee,
        .howAreYou
    ]
}

