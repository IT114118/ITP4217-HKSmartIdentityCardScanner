//
//  AddCardView.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 29/4/2021.
//

import SwiftUI
import CoreData
import ImagePickerView
// import SwiftyTesseract

struct AddCardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var showView: Bool
    
    @ObservedObject var cardData = CardData()
    
    @State var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var showImagePicker: Bool = false
    @State var image: UIImage?

    var body: some View {
        NavigationView {
            Group {
                Form {
                    Section(header: Text("SOURCE")) {
                        Button("Choose Image...") {
                            self.sourceType = .photoLibrary
                            self.showImagePicker.toggle()
                        }
                        .disabled(self.cardData.isRecognizing())
                        
                        Button("Open Camera...") {
                            self.sourceType = .camera
                            self.showImagePicker.toggle()
                        }
                        .disabled(self.cardData.isRecognizing())
                        
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    
                    Section(header: Text("INFORMATION")) {
                        if cardData.isRecognizing() {
                            ProgressView()
                        } else {
                            if let face = self.cardData.face {
                                Image(uiImage: face)
                                    .resizable()
                                    .frame(width: 50.0, height: 50.0)
                                    .clipShape(Circle())
                            }
                            
                            TextField("Chinese Name", text: $cardData.chineseName ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("English Name (Required)", text: $cardData.englishName ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Chinese Commerical Code", text: $cardData.cccString ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Date Of Birth (Required)", text: $cardData.dateOfBirth ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Sex (Required)", text: $cardData.sex ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Symbols (Required)", text: $cardData.symbols ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Date Of Issue (Required)", text: $cardData.dateOfIssue ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Date Of Registration (Required)", text: $cardData.dateOfRegistration ?? "")
                                .disableAutocorrection(true)
                            
                            TextField("Number (Required)", text: $cardData.number ?? "")
                                .disableAutocorrection(true)
                        }
                    }
                    .disabled(self.cardData.isRecognizing())
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(sourceType: self.sourceType) { image in
                    self.image = UIImage(data: image.jpegData(compressionQuality: 1.0)!)
                    cardData.reset()
                    cardData.recognize(in: self.image!)
                }
            }
            .navigationBarTitle(Text("Add Card"), displayMode: .inline)
            .navigationBarItems(
                leading: Section {
                    Button(action: {
                        print("Dismissing sheet view...")
                        self.showView = false
                    }) {
                        Text("Cancel")
                    }
                }
                .disabled(self.cardData.isRecognizing()),
                trailing: Section {
                    Button(action: {
                        self.addItem()
                        self.showView = false
                    }) {
                        Text("Save")
                    }
                }
                .disabled(!self.cardData.isAllowSave())
            )
        }
    }
    
    private func addItem() {
        withAnimation {
            let newCard = Card(context: viewContext)
            newCard.chineseName = cardData.chineseName
            newCard.englishName = cardData.englishName
            newCard.dateOfBirth = cardData.dateOfBirth
            newCard.dateOfIssue = cardData.dateOfIssue
            newCard.dateOfRegistration = cardData.dateOfRegistration
            newCard.sex = cardData.sex
            newCard.cccString = cardData.cccString
            newCard.symbols = cardData.symbols
            newCard.number = cardData.number
            newCard.face = cardData.face?.jpegData(compressionQuality: 1.0)
            newCard.source = cardData.source?.jpegData(compressionQuality: 1.0)

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

/*
struct AddCardView_Previews: PreviewProvider {
    static var previews: some View {
        AddCardView()
    }
}
*/
