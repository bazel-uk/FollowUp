//
//  ContactModalView.swift
//  FollowUp
//
//  Created by Aaron Baw on 17/10/2021.
//

import SwiftUI

struct ContactModalView: View {
    
    // MARK: - Environment
    @EnvironmentObject var followUpManager: FollowUpManager

    // MARK: - Stored Properties
    var sheet: ContactSheet
    var onClose: () -> Void
    var verticalSpacing: CGFloat = Constant.ContactModal.verticalSpacing
    
    // MARK: - Computed Properties
    var relativeTimeSinceMeetingString: String {
        Constant.relativeDateTimeFormatter.localizedString(for: contact.createDate, relativeTo: .now)
    }

    private var relativeTimeSinceFollowingUp: String {
        guard let lastFollowedUpDate = contact.lastFollowedUp else { return "Never" }
        return Constant.relativeDateTimeFormatter
            .localizedString(
                for: lastFollowedUpDate,
                   relativeTo: .now
            )
    }
    
    private var relativeTimeSinceMeetingView: some View {
        (Text(Image(icon: .clock)) +
         Text(" Met ") +
         Text(relativeTimeSinceMeetingString))
            .fontWeight(.medium)
    }

    private var contact: Contact {
        followUpManager.store.contact(forID: sheet.contactID)?.concrete ?? .unknown
    }
    
    // MARK: - Views
    @ViewBuilder
    private var contactBadgeAndNameView: some View {
        BadgeView(
            name: contact.name,
            image: contact.thumbnailImage,
            size: .large
        )
        Text(contact.name)
            .font(.largeTitle)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var contactDetailsView: some View {
        VStack {
            if let phoneNumber = contact.phoneNumber {
                Text(phoneNumber.value)
                    .font(.title2)
                    .foregroundColor(.secondary)
                HStack {
                    CircularButton(icon: .phone, action: .call(number: phoneNumber))
                    CircularButton(icon: .sms, action: .sms(number: phoneNumber))
                    CircularButton(icon: .whatsApp, action: .whatsApp(number: phoneNumber))
                }
            }
        }
    }

    @ViewBuilder
    private var followUpDetailsView: some View {
        VStack {
            Text("Last followed up: \(relativeTimeSinceFollowingUp)")
            Text("Total follow ups: \(contact.followUps)")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

    // MARK: - Buttons
    private var highlightButton: some View {
        Button(action: {
            followUpManager
                .contactsInteractor
                .highlight(contact)
        }, label: {
            VStack {
                Image(icon: .star)
                Text("Highlight")
            }
        })
        .accentColor(.yellow)
    }

    private var unhighlightButton: some View {
        Button(action: {
            followUpManager
                .contactsInteractor
                .unhighlight(contact)
        }, label: {
            VStack {
                Image(icon: .slashedStar)
                Text("Unhighlight")
            }
        })
        .accentColor(.orange)
    }

    private var followedUpButton: some View {
        Button(action: {
            followUpManager
                .contactsInteractor
                .markAsFollowedUp(contact)
        }, label: {
            VStack {
                Image(icon: .thumbsUp)
                Text("I followed up")
            }
        })
        .accentColor(.green)
        .disabled(contact.hasBeenFollowedUpToday)
    }

    private var addToFollowUpsButton: some View {
        Button(action: {
            followUpManager
                .contactsInteractor
                .addToFollowUps(contact)
        }, label: {
            VStack {
                Image(icon: .plus)
                Text("Add to follow ups")
            }
        })
    }

    private var removeFromFollowUpsButton: some View {
        Button(action: {
            followUpManager
                .contactsInteractor
                .removeFromFollowUps(contact)
        }, label: {
            VStack {
                Image(icon: .minus)
                Text("Remove from follow ups")
            }
        })
    }

    private var actionButtonGrid: some View {
        LazyVGrid(columns: [
            .init(), .init(), .init()
        ], alignment: .center, content: {
  
            
            if !contact.highlighted { highlightButton } else { unhighlightButton }
            if !contact.containedInFollowUps { addToFollowUpsButton } else { removeFromFollowUpsButton }
            followedUpButton
            
        })
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {

            
            HStack {
                Spacer()
                CloseButton(onClose: onClose)
                    .padding([.top, .trailing])
            }
            Spacer()
            
            contactBadgeAndNameView
            
            if let note = contact.note, !note.isEmpty {
                Text(note)
                    .italic()
            }
            
            relativeTimeSinceMeetingView
            
            contactDetailsView
                .padding(.top)
            Spacer()
            followUpDetailsView
            Spacer()
            actionButtonGrid
                .padding()
        }
    }
    
}

struct ContactModalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContactModalView(sheet: MockedContact(id: "1").sheet, onClose: { })
            ContactModalView(sheet: MockedContact(id: "0").sheet, onClose: { })
            ContactModalView(sheet: MockedContact(id: "0").sheet, onClose: { })
                .preferredColorScheme(.dark)
        }
        .environmentObject(FollowUpManager(store: .mocked(withNumberOfContacts: 5)))
    }
}
