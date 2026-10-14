import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift notice.
    final class ShiftNoticeView {
        var code: String
        var label: String
        var timezoneText: String
        var category: String
        var externalRef: String
        var amountText: String
        var capacityText: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, category: String, externalRef: String, amountText: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.category = category
            self.externalRef = externalRef
            self.amountText = amountText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toShiftNoticeView(_ item: ShiftNotice) -> ShiftNoticeView {
        return ShiftNoticeView(
            code: item.code,
            label: item.label,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 80),
            category: Kit.Text.truncate(item.category, limit: 40),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            amountText: String(format: "%.2f", item.amount),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftNoticeViews(_ items: [ShiftNotice]) -> [ShiftNoticeView] {
        var views: [ShiftNoticeView] = []
        for item in items {
            views.append(toShiftNoticeView(item))
        }
        return views
    }

    static func sumShiftNoticeView(_ view: ShiftNoticeView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedAmount + Double(parsedCapacity)
    }
}
