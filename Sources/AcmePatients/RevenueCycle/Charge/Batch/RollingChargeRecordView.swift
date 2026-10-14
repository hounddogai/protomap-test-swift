import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling charge record.
    final class RollingChargeRecordView {
        var codeText: String
        var nameText: String
        var active: String
        var amount: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, nameText: String, active: String, amount: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.active = active
            self.amount = amount
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toRollingChargeRecordView(_ item: RollingChargeRecord) -> RollingChargeRecordView {
        return RollingChargeRecordView(
            codeText: item.code,
            nameText: item.name,
            active: "\(item.active)",
            amount: String(format: "%.2f", item.amount),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingChargeRecordViews(_ items: [RollingChargeRecord]) -> [RollingChargeRecordView] {
        var views: [RollingChargeRecordView] = []
        for item in items {
            views.append(toRollingChargeRecordView(item))
        }
        return views
    }

    static func sumRollingChargeRecordView(_ view: RollingChargeRecordView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedAmount + parsedMaximum
    }
}
