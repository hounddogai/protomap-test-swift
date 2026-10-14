import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language cycle.
    final class LanguageCycleView {
        var code: String
        var labelText: String
        var locale: String
        var active: String
        var revision: String
        var checksum: String
        var budget: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, locale: String, active: String, revision: String, checksum: String, budget: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.locale = locale
            self.active = active
            self.revision = revision
            self.checksum = checksum
            self.budget = budget
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageCycleView(_ item: LanguageCycle) -> LanguageCycleView {
        return LanguageCycleView(
            code: item.code,
            labelText: item.label,
            locale: item.locale,
            active: "\(item.active)",
            revision: String(item.revision),
            checksum: item.checksum,
            budget: String(format: "%.2f", item.budget),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageCycleViews(_ items: [LanguageCycle]) -> [LanguageCycleView] {
        var views: [LanguageCycleView] = []
        for item in items {
            views.append(toLanguageCycleView(item))
        }
        return views
    }

    static func sumLanguageCycleView(_ view: LanguageCycleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRevision) + parsedBudget
    }
}
