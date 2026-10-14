import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority record.
    final class PriorityRecordView {
        var code: String
        var name: String
        var cost: String
        var reviewer: String
        var minimum: String
        var copay: String
        var version: String
        var statusLabel: String

        init(code: String, name: String, cost: String, reviewer: String, minimum: String, copay: String, version: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.reviewer = reviewer
            self.minimum = minimum
            self.copay = copay
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityRecordView(_ item: PriorityRecord) -> PriorityRecordView {
        return PriorityRecordView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            copay: String(format: "%.2f", item.copay),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityRecordViews(_ items: [PriorityRecord]) -> [PriorityRecordView] {
        var views: [PriorityRecordView] = []
        for item in items {
            views.append(toPriorityRecordView(item))
        }
        return views
    }

    static func sumPriorityRecordView(_ view: PriorityRecordView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCost + parsedMinimum + parsedCopay
    }
}
