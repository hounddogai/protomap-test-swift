import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling result override.
    final class RollingResultOverrideView {
        var codeText: String
        var labelText: String
        var approvedText: String
        var refills: String
        var durationMinutes: String
        var pinned: String
        var score: String
        var timezone: String
        var copay: String
        var statusLabel: String

        init(codeText: String, labelText: String, approvedText: String, refills: String, durationMinutes: String, pinned: String, score: String, timezone: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.approvedText = approvedText
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.score = score
            self.timezone = timezone
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toRollingResultOverrideView(_ item: RollingResultOverride) -> RollingResultOverrideView {
        return RollingResultOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            approvedText: "\(item.approved)",
            refills: String(item.refills),
            durationMinutes: String(item.durationMinutes),
            pinned: "\(item.pinned)",
            score: String(format: "%.2f", item.score),
            timezone: item.timezone,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingResultOverrideViews(_ items: [RollingResultOverride]) -> [RollingResultOverrideView] {
        var views: [RollingResultOverrideView] = []
        for item in items {
            views.append(toRollingResultOverrideView(item))
        }
        return views
    }

    static func sumRollingResultOverrideView(_ view: RollingResultOverrideView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRefills) + Double(parsedDurationMinutes) + parsedScore
    }
}
