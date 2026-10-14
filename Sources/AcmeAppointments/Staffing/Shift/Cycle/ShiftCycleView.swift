import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift cycle.
    final class ShiftCycleView {
        var code: String
        var name: String
        var reviewerText: String
        var notes: String
        var cost: String
        var timezone: String
        var copay: String
        var statusLabel: String

        init(code: String, name: String, reviewerText: String, notes: String, cost: String, timezone: String, copay: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewerText = reviewerText
            self.notes = notes
            self.cost = cost
            self.timezone = timezone
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toShiftCycleView(_ item: ShiftCycle) -> ShiftCycleView {
        return ShiftCycleView(
            code: item.code,
            name: item.name,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            notes: item.notes,
            cost: String(format: "%.2f", item.cost),
            timezone: item.timezone,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftCycleViews(_ items: [ShiftCycle]) -> [ShiftCycleView] {
        var views: [ShiftCycleView] = []
        for item in items {
            views.append(toShiftCycleView(item))
        }
        return views
    }

    static func sumShiftCycleView(_ view: ShiftCycleView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCost + parsedCopay
    }
}
