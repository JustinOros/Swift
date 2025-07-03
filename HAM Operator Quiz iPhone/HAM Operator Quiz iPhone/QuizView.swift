import SwiftUI

struct QuizQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let correct: Int
    let answers: [String]
}

struct QuizView: View {
    let testName: String

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var score = 0
    @State private var feedbackText = ""
    @State private var feedbackColor = Color.primary
    @State private var loadError = false
    @State private var showResults = false
    @State private var showSummaryAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if loadError {
                Text("Could not load questions for \(testName). Make sure the .json file is included in the app bundle or Documents folder.")
                    .foregroundColor(.red)
                    .padding()
            } else if questions.isEmpty {
                Text("Loading questions...")
                    .padding()
            } else if currentIndex < questions.count {
                Text(questions[currentIndex].question)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(questions[currentIndex].answers, id: \.self) { answer in
                    Button(action: {
                        selectedAnswer = answer
                        checkAnswer()

                        let correctAnswer = questions[currentIndex].answers[questions[currentIndex].correct]
                        let delay = (answer == correctAnswer) ? 3.0 : 5.0

                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            if selectedAnswer != nil {
                                nextQuestion()
                            }
                        }
                    }) {
                        Text(answer)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Capsule()
                                    .fill(bubbleColor(for: answer))
                            )
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text(feedbackText)
                    .foregroundColor(feedbackColor)

                HStack {
                    Button("Next") {
                        nextQuestion()
                    }
                    .disabled(selectedAnswer == nil)
                    .tint(Color.blue)

                    Spacer()

                    Button("Quit") {
                        showSummaryAlert = true
                    }
                    .tint(Color.gray)
                }
                .padding(.top, 10)

            } else {
                VStack(spacing: 10) {
                    Text("Quiz Complete!")
                        .font(.title)

                    let percentage = questions.count > 0 ? Int((Double(score) / Double(questions.count)) * 100) : 0
                    Text("You got \(score) out of \(questions.count) correct. (\(percentage)%)")
                }
            }
        }
        .padding()
        .onAppear(perform: syncAndLoadQuestions)
        .navigationTitle(testName + " Test")
        .alert(isPresented: $showSummaryAlert) {
            let percentage = currentIndex > 0 ? Int((Double(score) / Double(currentIndex + 1)) * 100) : 0
            return Alert(
                title: Text("Quiz Summary"),
                message: Text("You answered \(score) out of \(currentIndex + 1) correctly. (\(percentage)% correct)"),
                dismissButton: .default(Text("OK"), action: {
                    exit(0)
                })
            )
        }
    }

    func bubbleColor(for answer: String) -> Color {
        let imessageBlue = Color(red: 0.0, green: 122/255, blue: 1.0)
        let correctAnswer = questions[currentIndex].answers[questions[currentIndex].correct]
        if let selected = selectedAnswer {
            if selected == answer && selected == correctAnswer {
                return .green
            } else if selected == answer && selected != correctAnswer {
                return .red
            } else if answer == correctAnswer && selected != correctAnswer {
                return .green
            }
        }
        return imessageBlue
    }

    func syncAndLoadQuestions() {
        guard let documentsDir = getDocumentsDirectory() else {
            loadError = true
            return
        }

        let lowerName = testName.lowercased()
        let filename = "\(lowerName).json"
        let urlMap = [
            "technician": "https://raw.githubusercontent.com/russolsen/ham_radio_question_pool/master/technician-2022-2026/technician.json",
            "general": "https://raw.githubusercontent.com/russolsen/ham_radio_question_pool/master/general-2023-2027/general.json",
            "extra": "https://raw.githubusercontent.com/russolsen/ham_radio_question_pool/master/extra-2024-2028/extra.json"
        ]

        guard let remoteUrlString = urlMap[lowerName],
              let remoteUrl = URL(string: remoteUrlString) else {
            loadError = true
            return
        }

        let localFileURL = documentsDir.appendingPathComponent(filename)

        let fileExists = FileManager.default.fileExists(atPath: localFileURL.path)

        if !fileExists {
            downloadAndSave(remoteUrl: remoteUrl, to: localFileURL)
        } else {
            URLSession.shared.dataTask(with: remoteUrl) { data, response, error in
                if let data = data,
                   let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    do {
                        let remoteQuestions = try JSONDecoder().decode([QuizQuestion].self, from: data)
                        if let localData = try? Data(contentsOf: localFileURL),
                           let localQuestions = try? JSONDecoder().decode([QuizQuestion].self, from: localData),
                           localQuestions.count == remoteQuestions.count {
                            loadQuestions(from: localFileURL)
                        } else {
                            try data.write(to: localFileURL)
                            loadQuestions(from: localFileURL)
                        }
                    } catch {
                        print("Failed sync check: \(error)")
                        loadQuestions(from: localFileURL)
                    }
                } else {
                    print("Remote check failed: \(error?.localizedDescription ?? "Unknown")")
                    loadQuestions(from: localFileURL)
                }
            }.resume()
        }
    }

    func downloadAndSave(remoteUrl: URL, to localUrl: URL) {
        URLSession.shared.dataTask(with: remoteUrl) { data, response, error in
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                do {
                    try data.write(to: localUrl)
                    loadQuestions(from: localUrl)
                } catch {
                    print("Failed to save downloaded JSON: \(error)")
                    loadError = true
                }
            } else {
                print("Download failed: \(error?.localizedDescription ?? "Unknown")")
                loadError = true
            }
        }.resume()
    }

    func loadQuestions(from fileURL: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let loadedQuestions = try JSONDecoder().decode([QuizQuestion].self, from: data)

                DispatchQueue.main.async {
                    if loadedQuestions.isEmpty {
                        loadError = true
                    } else {
                        questions = loadedQuestions.shuffled()
                        loadError = false
                    }
                }
            } catch {
                print("Failed to parse questions: \(error)")
                DispatchQueue.main.async {
                    loadError = true
                }
            }
        }
    }

    func checkAnswer() {
        let correctAnswer = questions[currentIndex].answers[questions[currentIndex].correct]
        if selectedAnswer == correctAnswer {
            score += 1
            feedbackText = "Correct!"
            feedbackColor = .green
        } else {
            feedbackText = "Incorrect! Correct answer: \(correctAnswer)"
            feedbackColor = .red
        }
    }

    func nextQuestion() {
        currentIndex += 1
        selectedAnswer = nil
        feedbackText = ""
    }

    func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
