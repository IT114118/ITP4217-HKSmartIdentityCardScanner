//
//  ContentView.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 5/4/2021.
//

import SwiftUI
import CoreData

import ImagePickerView
import Vision
import SwiftyTesseract

class ContentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var cardDara = CardData()
    
    private var textRecognitionService = TextRecognitionService()

    func recognizeText(from image: UIImage) {
        isLoading = true
        textRecognitionService.delegate = self
        guard let cgImage = image.cgImage else { isLoading = false
            return
        }
        textRecognitionService.recognizeText(in: cgImage)
        /*
        var tesseract = Tesseract(languages: [.english])
        
        var result: Result<String, Tesseract.Error> = tesseract.performOCR(on: image)
        
        print(result)
        
        tesseract = Tesseract(languages: [.chineseTraditional])
        
        result = tesseract.performOCR(on: image)
        
        print(result)*/
    }
}

extension ContentViewModel: TextRecognitionServiceDelegate {
    func didRecognizeTextFromImage(_ text: String) {
        isLoading = false
        
        cardDara.reset()
        
        let lines = text.split(whereSeparator: \.isNewline)
        
        for line in lines {
            cardDara.store(String(line))
        }
        
        //print(text)
        print(" ==== Final Result =====")
        cardDara.printResult()
        
        
        //currentNote.text.append(text)
        //currentNote.language = recognizeLanguage(in: currentNote)
    }
    
    func didFailRecognizeTextFromImage() {
        isLoading = false
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.timestamp, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State var showImagePicker: Bool = false
    @State var image: UIImage?
    @ObservedObject private var contentViewModel = ContentViewModel()
    
    @State private var isPresented = false

    var body: some View {
        TabView {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                Button("Pick image") {
                    self.showImagePicker.toggle()
                }
                
                Button("Recognize") {
                    if let image = image {
                        print("Click")
                        contentViewModel.recognizeText(from: image)
                    }
                }
                
                if contentViewModel.isLoading {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(sourceType: .photoLibrary) { image in
                    self.image = image
                }
            }
            .tabItem {
                Image(systemName: "photo.fill")
                Text("Upload")
            }
            
            List {
                ForEach(cards) { card in
                    //Text("Item at \(card.number!, formatter: itemFormatter)")
                    Text("Item at \(card.number!)")
                }
                .onDelete(perform: deleteItems)
                
                #if os(iOS)
                EditButton()
                #endif

                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif

                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
            .tabItem {
                Image(systemName: "folder.badge.person.crop")
                Text("Storage")
            }
            .navigationTitle("")
        }
        
    }

    private func addItem() {
        withAnimation {
            let newCard = Card(context: viewContext)
            newCard.number = "text number"

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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
