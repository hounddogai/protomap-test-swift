import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending credential request.
    final class PendingCredentialRequestView {
        var code: String
        var titleText: String
        var label: String
        var currency: String
        var source: String
        var specialtyText: String
        var allergyText: String
        var locale: String
        var endsAt: String
        var quantity: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, titleText: String, label: String, currency: String, source: String, specialtyText: String, allergyText: String, locale: String, endsAt: String, quantity: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.label = label
            self.currency = currency
            self.source = source
            self.specialtyText = specialtyText
            self.allergyText = allergyText
            self.locale = locale
            self.endsAt = endsAt
            self.quantity = quantity
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCredentialRequestView(_ item: PendingCredentialRequest) -> PendingCredentialRequestView {
        return PendingCredentialRequestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            label: item.label,
            currency: item.currency,
            source: Kit.Text.truncate(item.source, limit: 40),
            specialtyText: item.specialty,
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            locale: item.locale,
            endsAt: String(item.endsAt),
            quantity: String(item.quantity),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCredentialRequestViews(_ items: [PendingCredentialRequest]) -> [PendingCredentialRequestView] {
        var views: [PendingCredentialRequestView] = []
        for item in items {
            views.append(toPendingCredentialRequestView(item))
        }
        return views
    }

    static func sumPendingCredentialRequestView(_ view: PendingCredentialRequestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedQuantity) + Double(parsedBatchSize)
    }
}
