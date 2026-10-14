import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool ledger.
    final class FloatPoolLedgerView {
        var codeText: String
        var label: String
        var threshold: String
        var windowDays: String
        var pinned: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, label: String, threshold: String, windowDays: String, pinned: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.threshold = threshold
            self.windowDays = windowDays
            self.pinned = pinned
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolLedgerView(_ item: FloatPoolLedger) -> FloatPoolLedgerView {
        return FloatPoolLedgerView(
            codeText: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            windowDays: String(item.windowDays),
            pinned: "\(item.pinned)",
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolLedgerViews(_ items: [FloatPoolLedger]) -> [FloatPoolLedgerView] {
        var views: [FloatPoolLedgerView] = []
        for item in items {
            views.append(toFloatPoolLedgerView(item))
        }
        return views
    }

    static func sumFloatPoolLedgerView(_ view: FloatPoolLedgerView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedThreshold + Double(parsedWindowDays) + parsedAmount
    }
}
