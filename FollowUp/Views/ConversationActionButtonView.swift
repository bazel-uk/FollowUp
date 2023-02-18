//
//  ConversationActionButtonView.swift
//  FollowUp
//
//  Created by Aaron Baw on 01/10/2022.
//

import SwiftUI

struct ConversationActionButtonView: View {
    
    // MARK: - Enums
    var template: ConversationStarterTemplate
    var contact: any Contactable

    var maxWidth: CGFloat = Constant.ConversationActionButton.maxWidth
    
    // MARK: - Computed Properties
    var labelText: String {
        guard let label = template.label, !label.isEmpty else {
            return template.title
        }
        return label
    }
    
    var body: some View {
        Button(action: {
            Task {
                // TODO: Ensure proper error handling, and wrap this in an 'AsyncButton' component. (See: https://www.swiftbysundell.com/articles/building-an-async-swiftui-button/)
                do {
                    let action = try template.buttonAction(contact: contact)
                    await action?.closure()
                } catch {
                    Log.error("Could not perform button action: \(error.localizedDescription)")
                }
            }
        }, label: {
            Label(
                title: {
                    Text(labelText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: maxWidth)
                    
                },
                icon: { Image(icon: template.platform.icon).renderingMode(.template) }
            )
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
                .padding()
                .background(Color(.tertiarySystemFill))
                .cornerRadius(Constant.cornerRadius)
        })
    }

}

struct ConversationActionButtonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ConversationActionButtonView(template: .init(template: "Hey <NAME>!", platform: .whatsApp), contact: Contact.mocked)
        }
        .previewLayout(.sizeThatFits)
    }
}
