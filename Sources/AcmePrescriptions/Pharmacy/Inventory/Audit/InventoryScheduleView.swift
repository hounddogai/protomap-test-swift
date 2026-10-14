import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory schedule.
    final class InventoryScheduleView {
        var codeText: String
        var label: String
        var locale: String
        var unit: String
        var floorValue: String
        var refills: String
        var amount: String
        var summary: String
        var copay: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, label: String, locale: String, unit: String, floorValue: String, refills: String, amount: String, summary: String, copay: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.locale = locale
            self.unit = unit
            self.floorValue = floorValue
            self.refills = refills
            self.amount = amount
            self.summary = summary
            self.copay = copay
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryScheduleView(_ item: InventorySchedule) -> InventoryScheduleView {
        return InventoryScheduleView(
            codeText: item.code,
            label: item.label,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            unit: item.unit,
            floorValue: String(format: "%.2f", item.floorValue),
            refills: String(item.refills),
            amount: String(format: "%.2f", item.amount),
            summary: item.summary,
            copay: String(format: "%.2f", item.copay),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryScheduleViews(_ items: [InventorySchedule]) -> [InventoryScheduleView] {
        var views: [InventoryScheduleView] = []
        for item in items {
            views.append(toInventoryScheduleView(item))
        }
        return views
    }

    static func sumInventoryScheduleView(_ view: InventoryScheduleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedFloorValue + Double(parsedRefills) + parsedAmount
    }
}
