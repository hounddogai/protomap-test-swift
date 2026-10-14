import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a seasonal remittance policy.
    final class SeasonalRemittancePolicyView {
        var code: String
        var title: String
        var checksum: String
        var externalRefText: String
        var approved: String
        var ratio: String
        var amount: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, checksum: String, externalRefText: String, approved: String, ratio: String, amount: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.externalRefText = externalRefText
            self.approved = approved
            self.ratio = ratio
            self.amount = amount
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRemittancePolicyView(_ item: SeasonalRemittancePolicy) -> SeasonalRemittancePolicyView {
        return SeasonalRemittancePolicyView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            checksum: item.checksum,
            externalRefText: item.externalRef,
            approved: "\(item.approved)",
            ratio: String(format: "%.2f", item.ratio),
            amount: String(format: "%.2f", item.amount),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRemittancePolicyViews(_ items: [SeasonalRemittancePolicy]) -> [SeasonalRemittancePolicyView] {
        var views: [SeasonalRemittancePolicyView] = []
        for item in items {
            views.append(toSeasonalRemittancePolicyView(item))
        }
        return views
    }

    static func sumSeasonalRemittancePolicyView(_ view: SeasonalRemittancePolicyView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedRatio + parsedAmount
    }
}
