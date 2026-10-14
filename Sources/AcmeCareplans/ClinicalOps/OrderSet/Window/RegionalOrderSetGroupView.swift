import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional order set group.
    final class RegionalOrderSetGroupView {
        var code: String
        var nameText: String
        var ceiling: String
        var notes: String
        var patientRef: String
        var capacity: String
        var score: String
        var weight: String
        var attemptsText: String
        var approvedText: String
        var statusLabel: String

        init(code: String, nameText: String, ceiling: String, notes: String, patientRef: String, capacity: String, score: String, weight: String, attemptsText: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceiling = ceiling
            self.notes = notes
            self.patientRef = patientRef
            self.capacity = capacity
            self.score = score
            self.weight = weight
            self.attemptsText = attemptsText
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOrderSetGroupView(_ item: RegionalOrderSetGroup) -> RegionalOrderSetGroupView {
        return RegionalOrderSetGroupView(
            code: item.code,
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            notes: item.notes,
            patientRef: item.patientRef,
            capacity: String(item.capacity),
            score: String(format: "%.2f", item.score),
            weight: String(format: "%.2f", item.weight),
            attemptsText: String(item.attempts),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOrderSetGroupViews(_ items: [RegionalOrderSetGroup]) -> [RegionalOrderSetGroupView] {
        var views: [RegionalOrderSetGroupView] = []
        for item in items {
            views.append(toRegionalOrderSetGroupView(item))
        }
        return views
    }

    static func sumRegionalOrderSetGroupView(_ view: RegionalOrderSetGroupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCeiling + Double(parsedCapacity) + parsedScore
    }
}
