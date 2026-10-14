import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness manifest.
    final class WitnessManifestView {
        var codeText: String
        var titleText: String
        var externalRef: String
        var segment: String
        var expiresAtText: String
        var weight: String
        var contactEmail: String
        var version: String
        var statusLabel: String

        init(codeText: String, titleText: String, externalRef: String, segment: String, expiresAtText: String, weight: String, contactEmail: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.externalRef = externalRef
            self.segment = segment
            self.expiresAtText = expiresAtText
            self.weight = weight
            self.contactEmail = contactEmail
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessManifestView(_ item: WitnessManifest) -> WitnessManifestView {
        return WitnessManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            externalRef: item.externalRef,
            segment: item.segment,
            expiresAtText: String(item.expiresAt),
            weight: String(format: "%.2f", item.weight),
            contactEmail: item.contactEmail,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessManifestViews(_ items: [WitnessManifest]) -> [WitnessManifestView] {
        var views: [WitnessManifestView] = []
        for item in items {
            views.append(toWitnessManifestView(item))
        }
        return views
    }

    static func sumWitnessManifestView(_ view: WitnessManifestView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedExpiresAt) + parsedWeight + Double(parsedVersion)
    }
}
