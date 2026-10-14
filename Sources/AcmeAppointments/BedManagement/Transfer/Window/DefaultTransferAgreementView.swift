import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default transfer agreement.
    final class DefaultTransferAgreementView {
        var code: String
        var title: String
        var source: String
        var maximum: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, source: String, maximum: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.source = source
            self.maximum = maximum
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultTransferAgreementView(_ item: DefaultTransferAgreement) -> DefaultTransferAgreementView {
        return DefaultTransferAgreementView(
            code: item.code,
            title: item.title,
            source: item.source,
            maximum: String(format: "%.2f", item.maximum),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultTransferAgreementViews(_ items: [DefaultTransferAgreement]) -> [DefaultTransferAgreementView] {
        var views: [DefaultTransferAgreementView] = []
        for item in items {
            views.append(toDefaultTransferAgreementView(item))
        }
        return views
    }

    static func sumDefaultTransferAgreementView(_ view: DefaultTransferAgreementView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedMaximum + Double(parsedQuantity)
    }
}
