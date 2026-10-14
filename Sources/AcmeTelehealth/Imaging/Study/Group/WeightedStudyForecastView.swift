import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted study forecast.
    final class WeightedStudyForecastView {
        var codeText: String
        var name: String
        var notesText: String
        var amount: String
        var version: String
        var payer: String
        var capacity: String
        var ward: String
        var specialtyText: String
        var visitMinutes: String
        var summaryText: String
        var statusLabel: String

        init(codeText: String, name: String, notesText: String, amount: String, version: String, payer: String, capacity: String, ward: String, specialtyText: String, visitMinutes: String, summaryText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.notesText = notesText
            self.amount = amount
            self.version = version
            self.payer = payer
            self.capacity = capacity
            self.ward = ward
            self.specialtyText = specialtyText
            self.visitMinutes = visitMinutes
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedStudyForecastView(_ item: WeightedStudyForecast) -> WeightedStudyForecastView {
        return WeightedStudyForecastView(
            codeText: item.code,
            name: item.name,
            notesText: Kit.Text.truncate(item.notes, limit: 64),
            amount: String(format: "%.2f", item.amount),
            version: String(item.version),
            payer: item.payer,
            capacity: String(item.capacity),
            ward: item.ward,
            specialtyText: item.specialty,
            visitMinutes: String(item.visitMinutes),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedStudyForecastViews(_ items: [WeightedStudyForecast]) -> [WeightedStudyForecastView] {
        var views: [WeightedStudyForecastView] = []
        for item in items {
            views.append(toWeightedStudyForecastView(item))
        }
        return views
    }

    static func sumWeightedStudyForecastView(_ view: WeightedStudyForecastView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedAmount + Double(parsedVersion) + Double(parsedCapacity)
    }
}
