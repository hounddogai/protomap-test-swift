import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer checkpoint.
    final class TransferCheckpointView {
        var codeText: String
        var title: String
        var phone: String
        var externalRef: String
        var ceiling: String
        var amountText: String
        var segmentText: String
        var label: String
        var discountText: String
        var statusLabel: String

        init(codeText: String, title: String, phone: String, externalRef: String, ceiling: String, amountText: String, segmentText: String, label: String, discountText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.phone = phone
            self.externalRef = externalRef
            self.ceiling = ceiling
            self.amountText = amountText
            self.segmentText = segmentText
            self.label = label
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferCheckpointView(_ item: TransferCheckpoint) -> TransferCheckpointView {
        return TransferCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 40),
            phone: item.phone,
            externalRef: item.externalRef,
            ceiling: String(format: "%.2f", item.ceiling),
            amountText: String(format: "%.2f", item.amount),
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            label: item.label,
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferCheckpointViews(_ items: [TransferCheckpoint]) -> [TransferCheckpointView] {
        var views: [TransferCheckpointView] = []
        for item in items {
            views.append(toTransferCheckpointView(item))
        }
        return views
    }

    static func sumTransferCheckpointView(_ view: TransferCheckpointView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCeiling + parsedAmount + parsedDiscount
    }
}
