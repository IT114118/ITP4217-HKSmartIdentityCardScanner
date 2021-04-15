//
//  HomeView.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 5/4/2021.
//

import SwiftUI
import ImagePickerView
import Vision
import SwiftyTesseract

struct HomeView: View {
    @State var showImagePicker: Bool = false
    @State var image: UIImage?
    @ObservedObject var manager = ContentViewModel()
    
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
                Button("Text Recognize") {
                    if let image = image {
                        print("Click")
                        manager.recognizeText(from: image)
                    }
                }
                if manager.isLoading {
                    ProgressView()
                }
            }.sheet(isPresented: $showImagePicker) {
                ImagePickerView(sourceType: .photoLibrary) { image in
                    self.image = image
                }
            }.tabItem {
                Image(systemName: "photo.fill")
                Text("Upload")
            }
            Text("Nearby Screen")
                .tabItem {
                    Image(systemName: "folder.badge.person.crop")
                    Text("Storage")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
