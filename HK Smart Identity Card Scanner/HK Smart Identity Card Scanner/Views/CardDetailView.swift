//
//  CardDetailView.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 29/4/2021.
//

import SwiftUI

struct CardDetailView: View {
    var card: Card
    
    var body: some View {
        Form {
            if let source: Data = card.source, let image: UIImage = UIImage(data: source) {
                Section(header: Text("SOURCE")) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            
            Section(header: Text("INFORMATION")) {
                if let face: Data = card.face, let image: UIImage = UIImage(data: face) {
                    HStack {
                        Text("Holder's Digital Image")
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 50.0, height: 50.0)
                    }
                }
                
                HStack {
                    Text("Card Model")
                    Spacer()
                    
                    if card.model == 1 {
                        Text("NEW")
                    } else {
                        Text("OLD")
                    }
                }
                
                HStack {
                    Text("Chinese Name")
                    Spacer()
                    Text(card.chineseName ?? "")
                }
                
                HStack {
                    Text("English Name")
                    Spacer()
                    Text(card.englishName ?? "")
                }
                
                HStack {
                    Text("CCC")
                    Spacer()
                    Text(card.cccString ?? "")
                }
                
                HStack {
                    Text("Date of Birth")
                    Spacer()
                    Text(card.dateOfBirth ?? "")
                }
                
                HStack {
                    Text("Sex")
                    Spacer()
                    Text(card.sex ?? "")
                }
                
                HStack {
                    Text("Symbols")
                    Spacer()
                    Text(card.symbols ?? "")
                }
                
                HStack {
                    Text("Date of Issue")
                    Spacer()
                    Text(card.dateOfIssue ?? "")
                }
                
                Group {
                    HStack {
                        Text("Date of Registration")
                        Spacer()
                        Text(card.dateOfRegistration ?? "")
                    }
                    
                    HStack {
                        Text("Number")
                        Spacer()
                        Text(card.number ?? "")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitle(Text("Card Details"), displayMode: .inline)
    }
}

/*
struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CardDetailView(card: cards[0])
    }
}
 */
