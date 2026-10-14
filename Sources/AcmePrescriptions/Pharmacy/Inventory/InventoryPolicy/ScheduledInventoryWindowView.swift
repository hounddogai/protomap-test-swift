import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled inventory window.
    final class ScheduledInventoryWindowView {
        var code: String
        var label: String
        var cost: String
        var segment: String
        var diagnosisCodeText: String
        var bed: String
        var statusLabel: String

        init(code: String, label: String, cost: String, segment: String, diagnosisCodeText: String, bed: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.segment = segment
            self.diagnosisCodeText = diagnosisCodeText
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledInventoryWindowView(_ item: ScheduledInventoryWindow) -> ScheduledInventoryWindowView {
        return ScheduledInventoryWindowView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            cost: String(format: "%.2f", item.cost),
            segment: item.segment,
            diagnosisCodeText: item.diagnosisCode,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledInventoryWindowViews(_ items: [ScheduledInventoryWindow]) -> [ScheduledInventoryWindowView] {
        var views: [ScheduledInventoryWindowView] = []
        for item in items {
            views.append(toScheduledInventoryWindowView(item))
        }
        return views
    }

    static func sumScheduledInventoryWindowView(_ view: ScheduledInventoryWindowView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
