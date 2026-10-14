import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional proxy manifest.
    final class RegionalProxyManifestView {
        var code: String
        var label: String
        var discountText: String
        var dosageMg: String
        var title: String
        var summary: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, discountText: String, dosageMg: String, title: String, summary: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discountText = discountText
            self.dosageMg = dosageMg
            self.title = title
            self.summary = summary
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalProxyManifestView(_ item: RegionalProxyManifest) -> RegionalProxyManifestView {
        return RegionalProxyManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            discountText: String(format: "%.2f", item.discount),
            dosageMg: String(format: "%.2f", item.dosageMg),
            title: item.title,
            summary: item.summary,
            country: Kit.Text.truncate(item.country, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalProxyManifestViews(_ items: [RegionalProxyManifest]) -> [RegionalProxyManifestView] {
        var views: [RegionalProxyManifestView] = []
        for item in items {
            views.append(toRegionalProxyManifestView(item))
        }
        return views
    }

    static func sumRegionalProxyManifestView(_ view: RegionalProxyManifestView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDiscount + parsedDosageMg
    }
}
