import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim summary.
    final class ClaimSummaryView {
        var code: String
        var labelText: String
        var copay: String
        var endsAt: String
        var createdAt: String
        var timezone: String
        var graceDays: String
        var statusLabel: String

        init(code: String, labelText: String, copay: String, endsAt: String, createdAt: String, timezone: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.copay = copay
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.timezone = timezone
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toClaimSummaryView(_ item: ClaimSummary) -> ClaimSummaryView {
        return ClaimSummaryView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            copay: String(format: "%.2f", item.copay),
            endsAt: String(item.endsAt),
            createdAt: String(item.createdAt),
            timezone: item.timezone,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimSummaryViews(_ items: [ClaimSummary]) -> [ClaimSummaryView] {
        var views: [ClaimSummaryView] = []
        for item in items {
            views.append(toClaimSummaryView(item))
        }
        return views
    }

    static func sumClaimSummaryView(_ view: ClaimSummaryView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedCopay + Double(parsedEndsAt) + Double(parsedCreatedAt)
    }
}
