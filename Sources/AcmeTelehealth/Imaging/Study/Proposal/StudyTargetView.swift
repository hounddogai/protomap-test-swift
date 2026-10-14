import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study target.
    final class StudyTargetView {
        var code: String
        var labelText: String
        var weightText: String
        var ceiling: String
        var encounterID: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, labelText: String, weightText: String, ceiling: String, encounterID: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.weightText = weightText
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyTargetView(_ item: StudyTarget) -> StudyTargetView {
        return StudyTargetView(
            code: item.code,
            labelText: item.label,
            weightText: String(format: "%.2f", item.weight),
            ceiling: String(format: "%.2f", item.ceiling),
            encounterID: item.encounterID,
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyTargetViews(_ items: [StudyTarget]) -> [StudyTargetView] {
        var views: [StudyTargetView] = []
        for item in items {
            views.append(toStudyTargetView(item))
        }
        return views
    }

    static func sumStudyTargetView(_ view: StudyTargetView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedWeight + parsedCeiling + Double(parsedDurationMinutes)
    }
}
