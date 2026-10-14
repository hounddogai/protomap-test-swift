import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive statement allocation.
    final class AdaptiveStatementAllocationView {
        var code: String
        var title: String
        var threshold: String
        var active: String
        var durationMinutes: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, active: String, durationMinutes: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.active = active
            self.durationMinutes = durationMinutes
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStatementAllocationView(_ item: AdaptiveStatementAllocation) -> AdaptiveStatementAllocationView {
        return AdaptiveStatementAllocationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 80),
            threshold: String(format: "%.2f", item.threshold),
            active: "\(item.active)",
            durationMinutes: String(item.durationMinutes),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStatementAllocationViews(_ items: [AdaptiveStatementAllocation]) -> [AdaptiveStatementAllocationView] {
        var views: [AdaptiveStatementAllocationView] = []
        for item in items {
            views.append(toAdaptiveStatementAllocationView(item))
        }
        return views
    }

    static func sumAdaptiveStatementAllocationView(_ view: AdaptiveStatementAllocationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes) + Double(parsedEndsAt)
    }
}
