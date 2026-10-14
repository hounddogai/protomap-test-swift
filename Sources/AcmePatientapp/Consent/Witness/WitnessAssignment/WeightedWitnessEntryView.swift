import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a weighted witness entry.
    final class WeightedWitnessEntryView {
        var code: String
        var name: String
        var cost: String
        var dosageMgText: String
        var endsAtText: String
        var startsAt: String
        var maximumText: String
        var visitMinutes: String
        var createdAt: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, cost: String, dosageMgText: String, endsAtText: String, startsAt: String, maximumText: String, visitMinutes: String, createdAt: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.dosageMgText = dosageMgText
            self.endsAtText = endsAtText
            self.startsAt = startsAt
            self.maximumText = maximumText
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedWitnessEntryView(_ item: WeightedWitnessEntry) -> WeightedWitnessEntryView {
        return WeightedWitnessEntryView(
            code: item.code,
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            endsAtText: String(item.endsAt),
            startsAt: String(item.startsAt),
            maximumText: String(format: "%.2f", item.maximum),
            visitMinutes: String(item.visitMinutes),
            createdAt: String(item.createdAt),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedWitnessEntryViews(_ items: [WeightedWitnessEntry]) -> [WeightedWitnessEntryView] {
        var views: [WeightedWitnessEntryView] = []
        for item in items {
            views.append(toWeightedWitnessEntryView(item))
        }
        return views
    }

    static func sumWeightedWitnessEntryView(_ view: WeightedWitnessEntryView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCost + parsedDosageMg + Double(parsedEndsAt)
    }
}
