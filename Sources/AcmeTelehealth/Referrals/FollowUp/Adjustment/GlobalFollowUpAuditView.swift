import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global follow up audit.
    final class GlobalFollowUpAuditView {
        var code: String
        var label: String
        var startsAt: String
        var minimum: String
        var diagnosisCode: String
        var unit: String
        var localeText: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, minimum: String, diagnosisCode: String, unit: String, localeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFollowUpAuditView(_ item: GlobalFollowUpAudit) -> GlobalFollowUpAuditView {
        return GlobalFollowUpAuditView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            startsAt: String(item.startsAt),
            minimum: String(format: "%.2f", item.minimum),
            diagnosisCode: item.diagnosisCode,
            unit: item.unit,
            localeText: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFollowUpAuditViews(_ items: [GlobalFollowUpAudit]) -> [GlobalFollowUpAuditView] {
        var views: [GlobalFollowUpAuditView] = []
        for item in items {
            views.append(toGlobalFollowUpAuditView(item))
        }
        return views
    }

    static func sumGlobalFollowUpAuditView(_ view: GlobalFollowUpAuditView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedStartsAt) + parsedMinimum
    }
}
