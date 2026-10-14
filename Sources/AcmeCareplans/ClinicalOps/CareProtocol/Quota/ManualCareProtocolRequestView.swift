import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual care protocol request.
    final class ManualCareProtocolRequestView {
        var code: String
        var nameText: String
        var ratio: String
        var currency: String
        var summaryText: String
        var dosageMg: String
        var maximum: String
        var payer: String
        var channel: String
        var statusLabel: String

        init(code: String, nameText: String, ratio: String, currency: String, summaryText: String, dosageMg: String, maximum: String, payer: String, channel: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ratio = ratio
            self.currency = currency
            self.summaryText = summaryText
            self.dosageMg = dosageMg
            self.maximum = maximum
            self.payer = payer
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareProtocolRequestView(_ item: ManualCareProtocolRequest) -> ManualCareProtocolRequestView {
        return ManualCareProtocolRequestView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            currency: Kit.Text.truncate(item.currency, limit: 120),
            summaryText: item.summary,
            dosageMg: String(format: "%.2f", item.dosageMg),
            maximum: String(format: "%.2f", item.maximum),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareProtocolRequestViews(_ items: [ManualCareProtocolRequest]) -> [ManualCareProtocolRequestView] {
        var views: [ManualCareProtocolRequestView] = []
        for item in items {
            views.append(toManualCareProtocolRequestView(item))
        }
        return views
    }

    static func sumManualCareProtocolRequestView(_ view: ManualCareProtocolRequestView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRatio + parsedDosageMg + parsedMaximum
    }
}
