import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer agreement.
    final class TransferAgreementView {
        var code: String
        var label: String
        var batchSize: String
        var currency: String
        var externalRef: String
        var statusLabel: String

        init(code: String, label: String, batchSize: String, currency: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.currency = currency
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toTransferAgreementView(_ item: TransferAgreement) -> TransferAgreementView {
        return TransferAgreementView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            batchSize: String(item.batchSize),
            currency: item.currency,
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferAgreementViews(_ items: [TransferAgreement]) -> [TransferAgreementView] {
        var views: [TransferAgreementView] = []
        for item in items {
            views.append(toTransferAgreementView(item))
        }
        return views
    }

    static func sumTransferAgreementView(_ view: TransferAgreementView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
