import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered revocation manifest.
    final class TieredRevocationManifestView {
        var code: String
        var label: String
        var country: String
        var attempts: String
        var minimumText: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, country: String, attempts: String, minimumText: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.country = country
            self.attempts = attempts
            self.minimumText = minimumText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRevocationManifestView(_ item: TieredRevocationManifest) -> TieredRevocationManifestView {
        return TieredRevocationManifestView(
            code: item.code,
            label: item.label,
            country: Kit.Text.truncate(item.country, limit: 64),
            attempts: String(item.attempts),
            minimumText: String(format: "%.2f", item.minimum),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRevocationManifestViews(_ items: [TieredRevocationManifest]) -> [TieredRevocationManifestView] {
        var views: [TieredRevocationManifestView] = []
        for item in items {
            views.append(toTieredRevocationManifestView(item))
        }
        return views
    }

    static func sumTieredRevocationManifestView(_ view: TieredRevocationManifestView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAttempts) + parsedMinimum + parsedDosageMg
    }
}
