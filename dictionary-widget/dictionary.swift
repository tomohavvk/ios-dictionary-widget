//
//  english.swift
//  english
//
//  Created by IZ on 11.04.2024.
//

import WidgetKit
import SwiftUI
import Foundation
import AppIntents

// FIXME
let data: [String] = fetchData()

func fetchData() -> [String] {
    var results: [String] = []
    let semaphore = DispatchSemaphore(value: 0)

    if let savedResults = UserDefaults.standard.stringArray(forKey: "dictionary") {

        if savedResults.count != 0 {
            print("ALREADY SAVED")
            print(savedResults.count)
            return savedResults
        }

    }

    // FIXME
    guard let url = URL(string: "http://*.*.*.*:8080/api/v1/load?sourceLanguage=en&targetLanguage=uk&limit=10000&offset=0") else {
        print("Invalid URL")
        return results
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
        defer { semaphore.signal() } // Release the semaphore when the task completes

        if let error = error {
            print("Error fetching data: \(error.localizedDescription)")
            return
        }

        guard let data = data else {
            print("No data received")
            return
        }

        do {
            let decodedData = try JSONDecoder().decode([Translation].self, from: data)
            results = decodedData.map { "\($0.source) - \($0.target)" }
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
        }
    }.resume()

    semaphore.wait()
    UserDefaults.standard.set(results, forKey: "dictionary")
    return results
}

struct Provider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), text: "placeholder - плейсхолдер")
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), text: "snapshot - знимок")
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let totalCountdown = data.count - 1
        
        var entries = [SimpleEntry]()
        
        for i in stride(from: 0, through: totalCountdown * 2, by: 10) {
            
            let components = DateComponents(second: i)
            let refreshDate = Calendar.current.date(byAdding: components, to: Date())!
            
            let randomNumber = Int(arc4random_uniform(uint(data.count)))
            
            let entry = SimpleEntry(
                date: refreshDate,
                text: data[randomNumber]
            )
            
            entries.append(entry)
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct englishEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Text(entry.text)
        }
    }
}

struct dictionary: Widget {
    let kind: String = "dictionary"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            englishEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")
    
    
}

extension ConfigurationAppIntent {

}

struct Translation: Codable {
    let id: Int
    let source: String
    let target: String
    let sourceLanguage: String
    let targetLanguage: String
}

#Preview(as: .systemSmall)   {
    dictionary()
} timeline: {
    SimpleEntry(date: .now, text:  "text1")
    SimpleEntry(date: .now,  text:  "text2")
}
