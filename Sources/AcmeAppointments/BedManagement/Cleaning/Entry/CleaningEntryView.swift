import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning entry.
    final class CleaningEntryView {
        var code: String
        var title: String
        var checksum: String
        var budgetText: String
        var category: String
        var cost: String
        var floorValueText: String
        var visible: String
        var externalRef: String
        var statusLabel: String

        init(code: String, title: String, checksum: String, budgetText: String, category: String, cost: String, floorValueText: String, visible: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.budgetText = budgetText
            self.category = category
            self.cost = cost
            self.floorValueText = floorValueText
            self.visible = visible
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningEntryView(_ item: CleaningEntry) -> CleaningEntryView {
        return CleaningEntryView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            checksum: item.checksum,
            budgetText: String(format: "%.2f", item.budget),
            category: Kit.Text.truncate(item.category, limit: 120),
            cost: String(format: "%.2f", item.cost),
            floorValueText: String(format: "%.2f", item.floorValue),
            visible: "\(item.visible)",
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningEntryViews(_ items: [CleaningEntry]) -> [CleaningEntryView] {
        var views: [CleaningEntryView] = []
        for item in items {
            views.append(toCleaningEntryView(item))
        }
        return views
    }

    static func sumCleaningEntryView(_ view: CleaningEntryView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedBudget + parsedCost + parsedFloorValue
    }
}
