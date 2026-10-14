import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered interaction ledger.
    final class TieredInteractionLedgerView {
        var codeText: String
        var label: String
        var payerText: String
        var currency: String
        var source: String
        var diagnosisCode: String
        var phoneText: String
        var facility: String
        var regionText: String
        var margin: String
        var channelText: String
        var statusLabel: String

        init(codeText: String, label: String, payerText: String, currency: String, source: String, diagnosisCode: String, phoneText: String, facility: String, regionText: String, margin: String, channelText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.payerText = payerText
            self.currency = currency
            self.source = source
            self.diagnosisCode = diagnosisCode
            self.phoneText = phoneText
            self.facility = facility
            self.regionText = regionText
            self.margin = margin
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredInteractionLedgerView(_ item: TieredInteractionLedger) -> TieredInteractionLedgerView {
        return TieredInteractionLedgerView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            payerText: item.payer,
            currency: item.currency,
            source: item.source,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            facility: item.facility,
            regionText: item.region,
            margin: String(format: "%.2f", item.margin),
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredInteractionLedgerViews(_ items: [TieredInteractionLedger]) -> [TieredInteractionLedgerView] {
        var views: [TieredInteractionLedgerView] = []
        for item in items {
            views.append(toTieredInteractionLedgerView(item))
        }
        return views
    }

    static func sumTieredInteractionLedgerView(_ view: TieredInteractionLedgerView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
