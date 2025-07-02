import Foundation

struct FileSync {
    static let baseURL = "https://raw.githubusercontent.com/russolsen/ham_radio_question_pool/master"
    static let testPaths = [
        "technician": "technician-2022-2026/technician.json",
        "general": "general-2023-2027/general.json",
        "extra": "extra-2024-2028/extra.json"
    ]

    static func urlForTest(_ test: String) -> URL? {
        guard let path = testPaths[test.lowercased()] else { return nil }
        return URL(string: "\(baseURL)/\(path)")
    }

    static func localFileURL(test: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("\(test).json")
    }

    static func downloadAndSave(test: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard
            let url = urlForTest(test),
            let localURL = localFileURL(test: test)
        else {
            completion(.failure(NSError(domain: "Invalid URL or file path", code: 0)))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                try data.write(to: localURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
