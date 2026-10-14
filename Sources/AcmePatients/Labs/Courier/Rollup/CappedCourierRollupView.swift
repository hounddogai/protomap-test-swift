import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped courier rollup.
    final class CappedCourierRollupView {
        var code: String
        var name: String
        var timezone: String
        var visitMinutes: String
        var cost: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, timezone: String, visitMinutes: String, cost: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.visitMinutes = visitMinutes
            self.cost = cost
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCourierRollupView(_ item: CappedCourierRollup) -> CappedCourierRollupView {
        return CappedCourierRollupView(
            code: item.code,
            name: item.name,
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            visitMinutes: String(item.visitMinutes),
            cost: String(format: "%.2f", item.cost),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCourierRollupViews(_ items: [CappedCourierRollup]) -> [CappedCourierRollupView] {
        var views: [CappedCourierRollupView] = []
        for item in items {
            views.append(toCappedCourierRollupView(item))
        }
        return views
    }

    static func sumCappedCourierRollupView(_ view: CappedCourierRollupView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCost + Double(parsedEndsAt)
    }
}
