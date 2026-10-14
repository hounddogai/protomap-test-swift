import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure estimate.
    final class ClosureEstimateView {
        var codeText: String
        var name: String
        var windowDaysText: String
        var capacity: String
        var currency: String
        var statusLabel: String

        init(codeText: String, name: String, windowDaysText: String, capacity: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.windowDaysText = windowDaysText
            self.capacity = capacity
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toClosureEstimateView(_ item: ClosureEstimate) -> ClosureEstimateView {
        return ClosureEstimateView(
            codeText: item.code,
            name: item.name,
            windowDaysText: String(item.windowDays),
            capacity: String(item.capacity),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureEstimateViews(_ items: [ClosureEstimate]) -> [ClosureEstimateView] {
        var views: [ClosureEstimateView] = []
        for item in items {
            views.append(toClosureEstimateView(item))
        }
        return views
    }

    static func sumClosureEstimateView(_ view: ClosureEstimateView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedCapacity)
    }
}
