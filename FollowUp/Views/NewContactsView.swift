//
//  NewContactsView.swift
//  FollowUp
//
//  Created by Aaron Baw on 09/10/2021.
//

import SwiftUI

struct NewContactsView: View {

    @State var contacts: [Contact] = []

    @EnvironmentObject var contactsInteractor: ContactsInteractor

    // MARK: - Computed Properties

    private var sortedContacts: [Contact] {
        contactsInteractor
                    .contacts
                    .sorted(by: \.createDate)
                    .reversed()
    }

    private var contactSections: [ContactSection] {
        sortedContacts
            .grouped(by: \.dateGrouping)
            .map { grouping, contacts in
                .init(
                    contacts: contacts
                        .sorted(by: \.createDate)
                        .reversed(),
                    grouping: grouping
                )
            }
            .sorted(by: \.grouping)
//        [
//            .init(contacts: [RecentContact.mocked, .mocked, .mocked], grouping: .thisWeek),
//            .init(contacts: [RecentContact.mocked, RecentContact.mocked], grouping: .thisMonth)
//        ]
    }

    // MARK: - Views

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(contactSections) { section in
                    ContactListView(
                        section: section,
                        layoutDirection: section.grouping == .thisWeek ? .horizontal : .vertical
                    )
                }
                .padding(.vertical)
            }
        }
        .padding(.top)
        .background(Color(.systemGroupedBackground))
        .task {
            await self.contactsInteractor.fetchContacts()
        }
    }

}

struct NewContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NewContactsView(contacts: [])
            .background(Color(.systemGroupedBackground))
            .environmentObject(ContactsInteractor())
    }
}
