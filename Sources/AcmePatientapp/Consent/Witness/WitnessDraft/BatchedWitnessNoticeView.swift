import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched witness notice.
    final class BatchedWitnessNoticeView {
        var codeText: String
        var labelText: String
        var revisionText: String
        var discount: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, labelText: String, revisionText: String, discount: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.revisionText = revisionText
            self.discount = discount
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedWitnessNoticeView(_ item: BatchedWitnessNotice) -> BatchedWitnessNoticeView {
        return BatchedWitnessNoticeView(
            codeText: item.code,
            labelText: item.label,
            revisionText: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedWitnessNoticeViews(_ items: [BatchedWitnessNotice]) -> [BatchedWitnessNoticeView] {
        var views: [BatchedWitnessNoticeView] = []
        for item in items {
            views.append(toBatchedWitnessNoticeView(item))
        }
        return views
    }

    static func sumBatchedWitnessNoticeView(_ view: BatchedWitnessNoticeView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + Double(parsedQuantity)
    }
}
