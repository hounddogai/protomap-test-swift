import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling revocation manifest.
    final class RollingRevocationManifestView {
        var code: String
        var nameText: String
        var floorValue: String
        var payerText: String
        var countryText: String
        var statusLabel: String

        init(code: String, nameText: String, floorValue: String, payerText: String, countryText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.floorValue = floorValue
            self.payerText = payerText
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRevocationManifestView(_ item: RollingRevocationManifest) -> RollingRevocationManifestView {
        return RollingRevocationManifestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            payerText: item.payer,
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRevocationManifestViews(_ items: [RollingRevocationManifest]) -> [RollingRevocationManifestView] {
        var views: [RollingRevocationManifestView] = []
        for item in items {
            views.append(toRollingRevocationManifestView(item))
        }
        return views
    }

    static func sumRollingRevocationManifestView(_ view: RollingRevocationManifestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
