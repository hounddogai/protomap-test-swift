import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled isolation policy.
    final class ScheduledIsolationPolicyView {
        var code: String
        var name: String
        var durationMinutes: String
        var diagnosisCode: String
        var visibleText: String
        var expiresAt: String
        var allergy: String
        var category: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, diagnosisCode: String, visibleText: String, expiresAt: String, allergy: String, category: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.visibleText = visibleText
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledIsolationPolicyView(_ item: ScheduledIsolationPolicy) -> ScheduledIsolationPolicyView {
        return ScheduledIsolationPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            diagnosisCode: item.diagnosisCode,
            visibleText: "\(item.visible)",
            expiresAt: String(item.expiresAt),
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledIsolationPolicyViews(_ items: [ScheduledIsolationPolicy]) -> [ScheduledIsolationPolicyView] {
        var views: [ScheduledIsolationPolicyView] = []
        for item in items {
            views.append(toScheduledIsolationPolicyView(item))
        }
        return views
    }

    static func sumScheduledIsolationPolicyView(_ view: ScheduledIsolationPolicyView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
