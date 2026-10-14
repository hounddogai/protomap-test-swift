import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy claim manifest.
    final class LegacyClaimManifestView {
        var codeText: String
        var label: String
        var reviewerText: String
        var channel: String
        var encounterIDText: String
        var maximum: String
        var ownerIDText: String
        var specialty: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, label: String, reviewerText: String, channel: String, encounterIDText: String, maximum: String, ownerIDText: String, specialty: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.reviewerText = reviewerText
            self.channel = channel
            self.encounterIDText = encounterIDText
            self.maximum = maximum
            self.ownerIDText = ownerIDText
            self.specialty = specialty
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyClaimManifestView(_ item: LegacyClaimManifest) -> LegacyClaimManifestView {
        return LegacyClaimManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            reviewerText: item.reviewer,
            channel: item.channel,
            encounterIDText: item.encounterID,
            maximum: String(format: "%.2f", item.maximum),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyClaimManifestViews(_ items: [LegacyClaimManifest]) -> [LegacyClaimManifestView] {
        var views: [LegacyClaimManifestView] = []
        for item in items {
            views.append(toLegacyClaimManifestView(item))
        }
        return views
    }

    static func sumLegacyClaimManifestView(_ view: LegacyClaimManifestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
