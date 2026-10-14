import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled bed board target.
    final class ScheduledBedBoardTargetView {
        var code: String
        var label: String
        var ownerIDText: String
        var cost: String
        var graceDays: String
        var statusLabel: String

        init(code: String, label: String, ownerIDText: String, cost: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerIDText = ownerIDText
            self.cost = cost
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledBedBoardTargetView(_ item: ScheduledBedBoardTarget) -> ScheduledBedBoardTargetView {
        return ScheduledBedBoardTargetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            ownerIDText: item.ownerID,
            cost: String(format: "%.2f", item.cost),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledBedBoardTargetViews(_ items: [ScheduledBedBoardTarget]) -> [ScheduledBedBoardTargetView] {
        var views: [ScheduledBedBoardTargetView] = []
        for item in items {
            views.append(toScheduledBedBoardTargetView(item))
        }
        return views
    }

    static func sumScheduledBedBoardTargetView(_ view: ScheduledBedBoardTargetView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCost + Double(parsedGraceDays)
    }
}
