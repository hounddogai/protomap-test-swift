import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer batch.
    final class TransferBatchView {
        var code: String
        var title: String
        var pinned: String
        var segment: String
        var locale: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, pinned: String, segment: String, locale: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.segment = segment
            self.locale = locale
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toTransferBatchView(_ item: TransferBatch) -> TransferBatchView {
        return TransferBatchView(
            code: item.code,
            title: item.title,
            pinned: "\(item.pinned)",
            segment: item.segment,
            locale: item.locale,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferBatchViews(_ items: [TransferBatch]) -> [TransferBatchView] {
        var views: [TransferBatchView] = []
        for item in items {
            views.append(toTransferBatchView(item))
        }
        return views
    }

    static func sumTransferBatchView(_ view: TransferBatchView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
