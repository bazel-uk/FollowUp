//
//  TagsCarouselView.swift
//  FollowUp
//
//  Created by Aaron Baw on 14/06/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct TagsCarouselView: View {
    
    var contact: any Contactable
    
    @State private var tags: [Tag]
    @State var creatingTag: Bool = false
    @State var draggingTag: Tag?
    @FocusState var textFieldIsFocused: Bool
    @State var newTagTitle: String = ""
    
    @EnvironmentObject var followUpManager: FollowUpManager
    
    // MARK: - Init
    init(
        contact: any Contactable
    ) {
        self.contact = contact
        self._tags = .init(initialValue: Array(contact.tags))
    }
    
    // MARK: - Computed Properties
    private var addTagButton: some View {
        Button(action: {
            textFieldIsFocused = true
            creatingTag = true
        }, label: {
            Text("+")
        })
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding(.horizontal, Constant.Tag.horiztontalPadding)
        .padding(.vertical, Constant.Tag.verticalPadding)
        .background(Color(.systemGray3))
        .cornerRadius(5)
    }
    
    private var creatingTagView: some View {
        TextField(text: $newTagTitle, label: {
            Text("New tag")
        })
        .padding(.horizontal, Constant.Tag.horiztontalPadding)
        .padding(.vertical, Constant.Tag.verticalPadding)
        .overlay(
            RoundedRectangle(cornerRadius: Constant.Tag.cornerRadius).stroke(Color(.systemGray3), lineWidth: 1).padding(1)
        )
        .focused($textFieldIsFocused)
        .onSubmit(onCreateTagSubmit)
        .submitLabel(.go)
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(tags) { tag in
                    TagChipView(tag: tag, action: { changeTagColour(tag: tag) })
                        .onDrag {
                            self.draggingTag = tag
                            return NSItemProvider(object: String(tag.id) as NSString) // Use the `id` or unique identifier of your `Tag`
                        }
                        .onDrop(
                            of: [.plainText],
                            delegate:
                                DragRelocateDelegate(
                                    item: tag,
                                    localTags: $tags,
                                    currentlyDraggedItem: $draggingTag,
                                    commitTagChangesClosure: commitTagChanges
                                )
                        )
                        .contextMenu {
                            Button(
                                role: .destructive,
                                action: {
                                    delete(tag: tag)
                                },
                                label: { Label(title: { Text(.delete) }, icon: { Image(icon: .trash) })
                            })
                        }
                }
                .animation(.default, value: contact.tags)
                
                
                if creatingTag {
                    creatingTagView
                }
                
                addTagButton
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Methods
    func commitTagChanges() {
        followUpManager.contactsInteractor.set(tags: tags, for: contact)
    }
    
    func onCreateTagSubmit() {
        // Add the new tag to the list of tags.
        withAnimation {
            tags.append(.init(title: newTagTitle))
        }
        newTagTitle = ""
        creatingTag = false
        textFieldIsFocused = false
        self.followUpManager.contactsInteractor.set(tags: tags, for: contact)
    }
    
    func delete(tag: Tag) {
        withAnimation {
            self.tags.removeAll(where: { $0 == tag })
        }
        self.followUpManager.contactsInteractor.remove(tag: tag, from: contact)
    }
    
    func changeTagColour(tag: Tag) {
        withAnimation {
            self.followUpManager.contactsInteractor.changeColour(forTag: tag, toColour: .random(), forContact: contact)
        }
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: Tag
    @Binding var localTags: [Tag]
    @Binding var currentlyDraggedItem: Tag?
    var commitTagChangesClosure: () -> Void
    
    func dropEntered(info: DropInfo) {
        guard item != currentlyDraggedItem,
              let currentlyDraggedItem = currentlyDraggedItem,
              let fromIndex = localTags.firstIndex(where: { $0.id == currentlyDraggedItem.id }),
              let toIndex = localTags.firstIndex(where: { $0.id == item.id }),
              fromIndex != toIndex
        else { return }
        
        withAnimation {
            localTags.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        currentlyDraggedItem = nil
        commitTagChangesClosure()
        return true
    }
}

struct TagsCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        TagsCarouselView(contact: Contact.mocked)
    }
}
