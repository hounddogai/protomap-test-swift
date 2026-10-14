import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional credential tier.
    final class RegionalCredentialTierView {
        var codeText: String
        var nameText: String
        var localeText: String
        var channelText: String
        var source: String
        var checksumText: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, nameText: String, localeText: String, channelText: String, source: String, checksumText: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.localeText = localeText
            self.channelText = channelText
            self.source = source
            self.checksumText = checksumText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCredentialTierView(_ item: RegionalCredentialTier) -> RegionalCredentialTierView {
        return RegionalCredentialTierView(
            codeText: item.code,
            nameText: item.name,
            localeText: item.locale,
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            source: Kit.Text.truncate(item.source, limit: 64),
            checksumText: item.checksum,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCredentialTierViews(_ items: [RegionalCredentialTier]) -> [RegionalCredentialTierView] {
        var views: [RegionalCredentialTierView] = []
        for item in items {
            views.append(toRegionalCredentialTierView(item))
        }
        return views
    }

    static func sumRegionalCredentialTierView(_ view: RegionalCredentialTierView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
