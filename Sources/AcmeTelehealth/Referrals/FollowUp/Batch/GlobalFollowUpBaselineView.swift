import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global follow up baseline.
    final class GlobalFollowUpBaselineView {
        var code: String
        var label: String
        var patientRefText: String
        var localeText: String
        var approved: String
        var durationMinutesText: String
        var category: String
        var clinicianIDText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, patientRefText: String, localeText: String, approved: String, durationMinutesText: String, category: String, clinicianIDText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRefText = patientRefText
            self.localeText = localeText
            self.approved = approved
            self.durationMinutesText = durationMinutesText
            self.category = category
            self.clinicianIDText = clinicianIDText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFollowUpBaselineView(_ item: GlobalFollowUpBaseline) -> GlobalFollowUpBaselineView {
        return GlobalFollowUpBaselineView(
            code: item.code,
            label: item.label,
            patientRefText: item.patientRef,
            localeText: item.locale,
            approved: "\(item.approved)",
            durationMinutesText: String(item.durationMinutes),
            category: item.category,
            clinicianIDText: item.clinicianID,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFollowUpBaselineViews(_ items: [GlobalFollowUpBaseline]) -> [GlobalFollowUpBaselineView] {
        var views: [GlobalFollowUpBaselineView] = []
        for item in items {
            views.append(toGlobalFollowUpBaselineView(item))
        }
        return views
    }

    static func sumGlobalFollowUpBaselineView(_ view: GlobalFollowUpBaselineView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedEndsAt)
    }
}
