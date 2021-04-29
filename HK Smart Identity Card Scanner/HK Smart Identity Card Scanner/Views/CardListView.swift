//
//  CardListView.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 29/4/2021.
//

import SwiftUI
import LocalAuthentication

struct CardListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Card.englishName, ascending: true)], animation: .default)
    private var cards: FetchedResults<Card>
    
    @State var showView: Bool = false
    @State var editMode: EditMode = EditMode.inactive
    @State private var isUnlocked = false
    
    var body: some View {
        NavigationView {
            List {
                if self.isUnlocked {
                    if cards.count <= 0 {
                        Text("No Data")
                    } else {
                        ForEach(cards) { card in
                            NavigationLink(destination: CardDetailView(card: card)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        if let chineseName = card.chineseName {
                                            Text("\(chineseName)")
                                        }
                                        
                                        if let englishName = card.englishName {
                                            Text("\(englishName)")
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let face = card.face, let image = UIImage(data: face) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .clipShape(Circle())
                                            .frame(width: 50.0, height: 50.0)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                } else {
                    HStack(alignment: .center) {
                        Spacer()
                        Image(systemName: "faceid")
                        Button("Unlock") {
                            self.authenticate()
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarTitle("Cards")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        self.showView = true
                        self.editMode = EditMode.inactive
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Card")
                        }
                    }
                    .disabled(!self.isUnlocked || self.editMode == EditMode.active)
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton().disabled(cards.count <= 0 || !self.isUnlocked)
                }
            }
            .environment(\.editMode, self.$editMode)
        }
        .fullScreenCover(isPresented: $showView) {
            AddCardView(showView: self.$showView).environment(\.managedObjectContext, viewContext)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: authenticate)
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Biometry
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Cards Data") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        print("Authenticated Successfully")
                    } else {
                        print("Authenticated Fail")
                    }
                }
            }
        } else {
            print("No deviceOwnerAuthenticationWithBiometrics")
            
            // Passcode
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Cards Data") { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            self.isUnlocked = true
                            print("Authenticated Successfully")
                        } else {
                            print("Authenticated Fail")
                        }
                    }
                }
            } else {
                print("No deviceOwnerAuthentication")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { cards[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct CardListView_Previews: PreviewProvider {
    static var previews: some View {
        CardListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
