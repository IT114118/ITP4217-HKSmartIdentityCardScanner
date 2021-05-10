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
    
    @ObservedObject var cardData = CardViewModel()
    
    @State var showImagePicker: Bool = false
    @State var showCardScanner: Bool = false
    @State var showDoneClicked: Bool = false
    
    @State private var previewIndex = 0
    var previewOptions = ["NEW", "OLD"]

    var body: some View {
        NavigationView {
            Group {
                Form {
                    Section(header: Text("SOURCE")) {
                        if let image = cardData.source {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Button("Choose Image...") {
                                self.showImagePicker = true
                            }
                            .sheet(isPresented: $showImagePicker) {
                                ImagePickerView(sourceType: .photoLibrary) { image in
                                    cardData.recognize(in: UIImage(data: image.jpegData(compressionQuality: 1.0)!)!)
                                }
                            }
                            
                            Button("Open Camera...") {
                                self.showCardScanner.toggle()
                            }
                            .fullScreenCover(isPresented: $showCardScanner) {
                                NavigationView {
                                    CardScannerViewController(clicked: $showDoneClicked) { image in
                                        showDoneClicked = false
                                        
                                        if let uiImage = UIImage(data: image.jpegData(compressionQuality: 1.0)!) {
                                            cardData.recognize(in: uiImage)
                                        }
                                    }
                                    .navigationBarTitle(Text("HKID Card Scanner"), displayMode: .inline)
                                    .navigationBarItems(
                                        leading: Section {
                                            Button(action: {
                                                showCardScanner = false
                                            }) {
                                                Text("Cancel")
                                            }
                                        },
                                        trailing: Section {
                                            Button(action: {
                                                showDoneClicked = true
                                            }) {
                                                Text("Done")
                                            }
                                        }
                                        .disabled(showDoneClicked)
                                    )
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("MASKED")) {
                        if cardData.isRecognizing() {
                            ProgressView()
                        } else if let image = cardData.masked {
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
                                HStack {
                                    Text("Holder's Digital Image")
                                    Spacer()
                                    Image(uiImage: face)
                                        .resizable()
                                        .frame(width: 50.0, height: 50.0)
                                        .clipShape(Circle())
                                }
                            }
                            
                            if let model = self.cardData.cardModel, model > 0 {
                                HStack {
                                    Text("Card Model")
                                    Spacer()
                                    
                                    if model == 1 {
                                        Text("NEW")
                                    } else {
                                        Text("OLD")
                                    }
                                }
                            }
                        }
                            
                        Group {
                            if !cardData.isRecognizing() {
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
                    }
                    .disabled(self.cardData.isRecognizing())
                }
            }
            .alert(isPresented: $cardData.showAlert) {
                Alert(
                    title: Text("Warning"),
                    message: Text("No HKID Card detected\nPress Continue if you want to continue using the image..."),
                    primaryButton: .destructive(Text("Continue")) {
                        print("Continue...")
                    },
                    secondaryButton: .default(Text("Back")) {
                        print("Back...")
                        cardData.reset()
                    }
                )
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
            newCard.masked = cardData.masked?.jpegData(compressionQuality: 1.0)
            newCard.source = cardData.source?.jpegData(compressionQuality: 1.0)
            newCard.model = cardData.cardModel ?? CardViewModel.HKIDCardModel.unknown.rawValue

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
