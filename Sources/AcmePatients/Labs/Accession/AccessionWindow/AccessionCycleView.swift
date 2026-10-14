import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession cycle.
    final class AccessionCycleView {
        var code: String
        var labelText: String
        var archived: String
        var budget: String
        var diagnosisCode: String
        var visibleText: String
        var version: String
        var locale: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, labelText: String, archived: String, budget: String, diagnosisCode: String, visibleText: String, version: String, locale: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archived = archived
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.visibleText = visibleText
            self.version = version
            self.locale = locale
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionCycleView(_ item: AccessionCycle) -> AccessionCycleView {
        return AccessionCycleView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            archived: "\(item.archived)",
            budget: String(format: "%.2f", item.budget),
            diagnosisCode: item.diagnosisCode,
            visibleText: "\(item.visible)",
            version: String(item.version),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionCycleViews(_ items: [AccessionCycle]) -> [AccessionCycleView] {
        var views: [AccessionCycleView] = []
        for item in items {
            views.append(toAccessionCycleView(item))
        }
        return views
    }

    static func sumAccessionCycleView(_ view: AccessionCycleView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedBudget + Double(parsedVersion) + Double(parsedDurationMinutes)
    }
}
