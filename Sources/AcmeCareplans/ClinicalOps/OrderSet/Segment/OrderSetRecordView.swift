import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set record.
    final class OrderSetRecordView {
        var codeText: String
        var label: String
        var description: String
        var currency: String
        var copayText: String
        var statusLabel: String

        init(codeText: String, label: String, description: String, currency: String, copayText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.description = description
            self.currency = currency
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetRecordView(_ item: OrderSetRecord) -> OrderSetRecordView {
        return OrderSetRecordView(
            codeText: item.code,
            label: item.label,
            description: item.description,
            currency: item.currency,
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetRecordViews(_ items: [OrderSetRecord]) -> [OrderSetRecordView] {
        var views: [OrderSetRecordView] = []
        for item in items {
            views.append(toOrderSetRecordView(item))
        }
        return views
    }

    static func sumOrderSetRecordView(_ view: OrderSetRecordView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
