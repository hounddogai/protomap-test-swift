import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global shift profile.
    final class GlobalShiftProfileView {
        var codeText: String
        var nameText: String
        var score: String
        var copay: String
        var encounterID: String
        var weightText: String
        var startsAt: String
        var facility: String
        var statusLabel: String

        init(codeText: String, nameText: String, score: String, copay: String, encounterID: String, weightText: String, startsAt: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.score = score
            self.copay = copay
            self.encounterID = encounterID
            self.weightText = weightText
            self.startsAt = startsAt
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalShiftProfileView(_ item: GlobalShiftProfile) -> GlobalShiftProfileView {
        return GlobalShiftProfileView(
            codeText: item.code,
            nameText: item.name,
            score: String(format: "%.2f", item.score),
            copay: String(format: "%.2f", item.copay),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            weightText: String(format: "%.2f", item.weight),
            startsAt: String(item.startsAt),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalShiftProfileViews(_ items: [GlobalShiftProfile]) -> [GlobalShiftProfileView] {
        var views: [GlobalShiftProfileView] = []
        for item in items {
            views.append(toGlobalShiftProfileView(item))
        }
        return views
    }

    static func sumGlobalShiftProfileView(_ view: GlobalShiftProfileView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedScore + parsedCopay + parsedWeight
    }
}
