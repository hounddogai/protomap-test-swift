import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled denial claim.
    final class ScheduledDenialClaimView {
        var codeText: String
        var name: String
        var threshold: String
        var active: String
        var bed: String
        var statusLabel: String

        init(codeText: String, name: String, threshold: String, active: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.threshold = threshold
            self.active = active
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledDenialClaimView(_ item: ScheduledDenialClaim) -> ScheduledDenialClaimView {
        return ScheduledDenialClaimView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            active: "\(item.active)",
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledDenialClaimViews(_ items: [ScheduledDenialClaim]) -> [ScheduledDenialClaimView] {
        var views: [ScheduledDenialClaimView] = []
        for item in items {
            views.append(toScheduledDenialClaimView(item))
        }
        return views
    }

    static func sumScheduledDenialClaimView(_ view: ScheduledDenialClaimView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
