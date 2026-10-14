import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict order set tier.
    final class StrictOrderSetTierView {
        var codeText: String
        var title: String
        var encounterIDText: String
        var checksumText: String
        var discountText: String
        var attempts: String
        var phone: String
        var statusLabel: String

        init(codeText: String, title: String, encounterIDText: String, checksumText: String, discountText: String, attempts: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.encounterIDText = encounterIDText
            self.checksumText = checksumText
            self.discountText = discountText
            self.attempts = attempts
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toStrictOrderSetTierView(_ item: StrictOrderSetTier) -> StrictOrderSetTierView {
        return StrictOrderSetTierView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            encounterIDText: item.encounterID,
            checksumText: item.checksum,
            discountText: String(format: "%.2f", item.discount),
            attempts: String(item.attempts),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictOrderSetTierViews(_ items: [StrictOrderSetTier]) -> [StrictOrderSetTierView] {
        var views: [StrictOrderSetTierView] = []
        for item in items {
            views.append(toStrictOrderSetTierView(item))
        }
        return views
    }

    static func sumStrictOrderSetTierView(_ view: StrictOrderSetTierView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDiscount + Double(parsedAttempts)
    }
}
