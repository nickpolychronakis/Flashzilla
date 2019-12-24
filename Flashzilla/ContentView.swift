//
//  ContentView.swift
//  Flashzilla
//
//  Created by NICK POLYCHRONAKIS on 18/12/19.
//  Copyright © 2019 NICK POLYCHRONAKIS. All rights reserved.
//

import SwiftUI
import CoreHaptics

struct ContentView: View {
    
    @Environment(\EnvironmentValues.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
        
    @State private var cards = [Card]()
    
    @State private var timeRemaining = 100
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var isActive = true
    
    @State private var showingEditScreen = false
    
    @State private var showingSettingsScreen = false
    
    @State private var timerOffset = 0
    
    @State private var hapticEngine: CHHapticEngine?
    
    @State private var wrongCardGoesBack = true
    
    var body: some View {
        ZStack {
            // Φοντο
            Image(decorative: "background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            // Χρόνος, κάρτες
            VStack {
                // MARK: Time
                Text( timeRemaining > 0 ? "Time: \(timeRemaining)" : "Time is up!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black)
                            .opacity(0.75)
                    )
                    .padding(10)
                    .offset(CGSize(width: timerOffset, height: 0))

                // MARK: Reset button
                if cards.isEmpty || timeRemaining == 0 {
                    Button("Start Again", action: resetCards)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.scale)
                        .animation(.default)
                } else {
                    // MARK: Card list
                    ZStack {
                        ForEach(0..<cards.count, id: \.self) { index in
                            CardView(card: self.cards[index], isLastCard: index == 0) { isAnswerWrong in
                                withAnimation(Animation.spring()) {
                                    self.removeCard(at: index, isAnswerWrong: isAnswerWrong)
                                }
                            }
                            .stacked(at: index, in: self.cards.count)
                            .allowsHitTesting(index == self.cards.count - 1)
                            .accessibility(hidden: index < self.cards.count - 1)
                        }
                    }
                    .allowsHitTesting(timeRemaining > 0)
//                    .transition(.scale)
//                    .animation(.default)
                }
                

            }
            
            // MARK: Κουμπί Settings και προσθήκης πάνω δεξιά
            VStack {
                HStack {
                    Button(action: {
                        self.showingSettingsScreen = true
                    }) {
                        Image(systemName: "gear")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.showingEditScreen = true
                    }) {
                        Image(systemName: "plus.circle")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()

            
            // MARK: Αρχρωματοψία κουμπία
            if self.differentiateWithoutColor {
                VStack {
                    Spacer()

                    HStack {
                        Button.init(action: {
                            withAnimation {
                                self.removeCard(at: self.cards.count - 1,isAnswerWrong: true)
                            }
                        }) {
                            Image(systemName: "xmark.circle")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .accessibility(label: Text("Wrong"))
                        .accessibility(hint: Text("Mark your answer as being incorrect."))

                        Spacer()

                        Button.init(action: {
                            withAnimation {
                                self.removeCard(at: self.cards.count - 1,isAnswerWrong: false)
                            }
                        }) {
                            Image(systemName: "checkmark.circle")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .accessibility(label: Text("Correct"))
                        .accessibility(hint: Text("Mark your answer as being correct."))
                    }
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                }
            }
        }
        .onReceive(timer) { (time) in
            print("timer \(time) \(self.isActive)")
            guard self.isActive else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                if self.timeRemaining == 0 {
                    self.complexSuccess()
                    self.timerOffset = -5
                    withAnimation(Animation.spring().speed(20).repeatCount(4, autoreverses: true)) {
                        self.timerOffset = 5
                    }
                    
                    self.timerOffset = 0
                } else if self.timeRemaining == 1 {
                    self.prepareHaptics()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { (_) in
            self.isActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { (_) in
            if self.cards.isEmpty == false {
                self.isActive = true
            }
        }
        .sheet(isPresented: $showingEditScreen, onDismiss: resetCards) {
            EditCards()
        }
        .actionSheet(isPresented: $showingSettingsScreen, content: { () -> ActionSheet in
            ActionSheet(title: Text("Replay wrong answers?"), message: Text("Do you want to replay the wrong answers?"), buttons: [
                ActionSheet.Button.default(Text("Yes"), action: {
                    self.wrongCardGoesBack = true
                }),
                ActionSheet.Button.default(Text("No"), action: {
                    self.wrongCardGoesBack = false
                })
            ])
        })
        .onAppear(perform: resetCards)
    }
    
    
    
    
    
    // MARK: Remove Card func
    func removeCard(at index: Int, isAnswerWrong: Bool) {
        guard index >= 0 else { return }

        if self.wrongCardGoesBack, isAnswerWrong {
            self.cards.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
        } else {
            cards.remove(at: index)
        }
        
        if cards.isEmpty {
            self.isActive = false
        }
    }
    // MARK: Reset Cards func
    func resetCards() {
        timeRemaining = 100
        isActive = true
        loadData()
        self.isActive = cards.count > 0
    }
    
    // MARK: Load data func
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "Cards") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                self.cards = decoded
            }
        }
    }
    
    // MARK: Start Haptic Engine
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            self.hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    // MARK: Create Haptic
    func complexSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription)")
        }
    }
    
}



extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = CGFloat(total - position)
        return self.offset(CGSize(width: 0, height: offset * 10))
    }
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
