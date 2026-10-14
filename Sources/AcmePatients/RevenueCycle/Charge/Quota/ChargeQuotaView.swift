import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge quota.
    final class ChargeQuotaView {
        var codeText: String
        var titleText: String
        var region: String
        var rateText: String
        var dosageMgText: String
        var summary: String
        var statusLabel: String

        init(codeText: String, titleText: String, region: String, rateText: String, dosageMgText: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.region = region
            self.rateText = rateText
            self.dosageMgText = dosageMgText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toChargeQuotaView(_ item: ChargeQuota) -> ChargeQuotaView {
        return ChargeQuotaView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            region: item.region,
            rateText: String(format: "%.2f", item.rate),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeQuotaViews(_ items: [ChargeQuota]) -> [ChargeQuotaView] {
        var views: [ChargeQuotaView] = []
        for item in items {
            views.append(toChargeQuotaView(item))
        }
        return views
    }

    static func sumChargeQuotaView(_ view: ChargeQuotaView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedRate + parsedDosageMg
    }
}
