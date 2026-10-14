import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge record.
    final class ChargeRecordView {
        var codeText: String
        var label: String
        var maximumText: String
        var retries: String
        var priority: String
        var statusLabel: String

        init(codeText: String, label: String, maximumText: String, retries: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.maximumText = maximumText
            self.retries = retries
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toChargeRecordView(_ item: ChargeRecord) -> ChargeRecordView {
        return ChargeRecordView(
            codeText: item.code,
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            retries: String(item.retries),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeRecordViews(_ items: [ChargeRecord]) -> [ChargeRecordView] {
        var views: [ChargeRecordView] = []
        for item in items {
            views.append(toChargeRecordView(item))
        }
        return views
    }

    static func sumChargeRecordView(_ view: ChargeRecordView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMaximum + Double(parsedRetries) + Double(parsedPriority)
    }
}
