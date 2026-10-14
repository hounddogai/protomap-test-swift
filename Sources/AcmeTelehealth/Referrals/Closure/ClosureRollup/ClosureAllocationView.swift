import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure allocation.
    final class ClosureAllocationView {
        var code: String
        var label: String
        var retries: String
        var ceiling: String
        var localeText: String
        var statusLabel: String

        init(code: String, label: String, retries: String, ceiling: String, localeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.ceiling = ceiling
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureAllocationView(_ item: ClosureAllocation) -> ClosureAllocationView {
        return ClosureAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            retries: String(item.retries),
            ceiling: String(format: "%.2f", item.ceiling),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureAllocationViews(_ items: [ClosureAllocation]) -> [ClosureAllocationView] {
        var views: [ClosureAllocationView] = []
        for item in items {
            views.append(toClosureAllocationView(item))
        }
        return views
    }

    static func sumClosureAllocationView(_ view: ClosureAllocationView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRetries) + parsedCeiling
    }
}
