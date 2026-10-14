import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict disclosure ledger.
    final class StrictDisclosureLedgerView {
        var code: String
        var name: String
        var acuity: String
        var ceilingText: String
        var discount: String
        var currencyText: String
        var region: String
        var score: String
        var ward: String
        var specialty: String
        var payer: String
        var statusLabel: String

        init(code: String, name: String, acuity: String, ceilingText: String, discount: String, currencyText: String, region: String, score: String, ward: String, specialty: String, payer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.ceilingText = ceilingText
            self.discount = discount
            self.currencyText = currencyText
            self.region = region
            self.score = score
            self.ward = ward
            self.specialty = specialty
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDisclosureLedgerView(_ item: StrictDisclosureLedger) -> StrictDisclosureLedgerView {
        return StrictDisclosureLedgerView(
            code: item.code,
            name: item.name,
            acuity: String(item.acuity),
            ceilingText: String(format: "%.2f", item.ceiling),
            discount: String(format: "%.2f", item.discount),
            currencyText: item.currency,
            region: Kit.Text.truncate(item.region, limit: 120),
            score: String(format: "%.2f", item.score),
            ward: item.ward,
            specialty: item.specialty,
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDisclosureLedgerViews(_ items: [StrictDisclosureLedger]) -> [StrictDisclosureLedgerView] {
        var views: [StrictDisclosureLedgerView] = []
        for item in items {
            views.append(toStrictDisclosureLedgerView(item))
        }
        return views
    }

    static func sumStrictDisclosureLedgerView(_ view: StrictDisclosureLedgerView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedAcuity) + parsedCeiling + parsedDiscount
    }
}
