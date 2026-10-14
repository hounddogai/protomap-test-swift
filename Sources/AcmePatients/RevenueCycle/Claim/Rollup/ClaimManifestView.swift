import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim manifest.
    final class ClaimManifestView {
        var codeText: String
        var name: String
        var maximum: String
        var externalRef: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, externalRef: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.externalRef = externalRef
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toClaimManifestView(_ item: ClaimManifest) -> ClaimManifestView {
        return ClaimManifestView(
            codeText: item.code,
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimManifestViews(_ items: [ClaimManifest]) -> [ClaimManifestView] {
        var views: [ClaimManifestView] = []
        for item in items {
            views.append(toClaimManifestView(item))
        }
        return views
    }

    static func sumClaimManifestView(_ view: ClaimManifestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt)
    }
}
