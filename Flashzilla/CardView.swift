//
//  CardView.swift
//  Flashzilla
//
//  Created by NICK POLYCHRONAKIS on 20/12/19.
//  Copyright © 2019 NICK POLYCHRONAKIS. All rights reserved.
//

import SwiftUI

struct CardView: View {
    
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    @Environment(\EnvironmentValues.accessibilityEnabled) var accessibilityEnabled
    
    @State private var isShowingAnswer = false
    
    @State private var offset = CGSize.zero
    
    let card: Card
    
    var isLastCard = false
    
    var removal: ((_ isAnswerWrong: Bool) -> Void)? = nil
    
    let feedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    self.differentiateWithoutColor
                        ? Color.white
                        : Color.white.opacity(1 - Double(abs(offset.width / 50))))
                .background(
                    self.differentiateWithoutColor
                        ? nil
                        : RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(offset.width > 0 ? Color.green : (offset.width < 0 ? Color.red : Color.white))
                )
                .shadow(radius: 10)
            
            VStack {
                if accessibilityEnabled {
                    Text(isShowingAnswer ? card.answer : card.prompt)
                } else {
                    Text(card.prompt)
                        .font(.largeTitle)
                    
                    if isShowingAnswer {
                        Text(card.answer)
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .multilineTextAlignment(.center)
            .animation(.none)
        }
        .frame(width: 450, height: 250)
        .rotationEffect(.degrees(Double(offset.width / 5)))
        .offset(x: offset.width * 5, y: 0)
        .opacity(2 - Double(abs(offset.width / 50)))
        .accessibility(addTraits: .isButton)
        .gesture(
            DragGesture()
                .onChanged({ (gesture) in
                    self.offset = gesture.translation
                    self.feedback.prepare()
                })
                .onEnded({ (_) in
                    if abs(self.offset.width) > 100 {
                        if self.offset.width > 0 {
                            self.feedback.notificationOccurred(.success)
                            self.removal?(false)
                        } else {
                            self.feedback.notificationOccurred(.error)
                            self.removal?(true)
                            if !self.isLastCard {
                                self.offset = .zero
                            } else {
                                withAnimation(Animation.spring().speed(0.5)) {
                                    self.offset = .zero
                                }
                            }
                            self.isShowingAnswer = false
                        }
                    } else {
                        withAnimation(Animation.spring().speed(0.5)){
                            self.offset = .zero
                        }
                    }
                })
        )
        .onTapGesture {
            self.isShowingAnswer.toggle()
        }
    }
}

//extension View {
//    func redOrGreen(red:Bool) -> some View {
//        if red {
//
//        }
//    }
//}



struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(card: Card.example)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("CardViewe")
    }
}
