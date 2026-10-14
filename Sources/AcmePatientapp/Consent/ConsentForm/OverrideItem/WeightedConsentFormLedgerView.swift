import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a weighted consent form ledger.
    final class WeightedConsentFormLedgerView {
        var code: String
        var nameText: String
        var payer: String
        var marginText: String
        var facility: String
        var batchSize: String
        var locale: String
        var currency: String
        var endsAt: String
        var ownerID: String
        var statusLabel: String

        init(code: String, nameText: String, payer: String, marginText: String, facility: String, batchSize: String, locale: String, currency: String, endsAt: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payer = payer
            self.marginText = marginText
            self.facility = facility
            self.batchSize = batchSize
            self.locale = locale
            self.currency = currency
            self.endsAt = endsAt
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedConsentFormLedgerView(_ item: WeightedConsentFormLedger) -> WeightedConsentFormLedgerView {
        return WeightedConsentFormLedgerView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            marginText: String(format: "%.2f", item.margin),
            facility: item.facility,
            batchSize: String(item.batchSize),
            locale: item.locale,
            currency: item.currency,
            endsAt: String(item.endsAt),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedConsentFormLedgerViews(_ items: [WeightedConsentFormLedger]) -> [WeightedConsentFormLedgerView] {
        var views: [WeightedConsentFormLedgerView] = []
        for item in items {
            views.append(toWeightedConsentFormLedgerView(item))
        }
        return views
    }

    static func sumWeightedConsentFormLedgerView(_ view: WeightedConsentFormLedgerView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMargin + Double(parsedBatchSize) + Double(parsedEndsAt)
    }
}
