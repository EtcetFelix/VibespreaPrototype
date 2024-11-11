//
//  DropDownButton.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/13/22.
//

import SwiftUI

struct DropDownButton: View {
    var buttonText: String
    var buttonDroppedText: String
    var buttonDroppedTruth: Bool
    var actionToTake: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(buttonText)
                Button(action: {
                    actionToTake()
                    },
                   label: {
                       Label("Graph", systemImage: "chevron.right.circle")
                           .labelStyle(.iconOnly)
                           .imageScale(.large)
                           .rotationEffect(
                               .degrees(buttonDroppedTruth ? 90 : 0))
                           .padding()
                           .animation(.easeInOut, value: buttonDroppedTruth)
                   }
                )

            }
            if buttonDroppedTruth {
                Text(buttonDroppedText)
                    .italic()
            }
        }
    }
}

struct DropDownButton_Previews: PreviewProvider {
    static var previews: some View {
        DropDownButton(buttonText: "Start Advertising", buttonDroppedText: "Advertising...", buttonDroppedTruth: false, actionToTake: {})
    }
}
