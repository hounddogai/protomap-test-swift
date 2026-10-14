import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending credential manifest.
    final class PendingCredentialManifestView {
        var code: String
        var label: String
        var minimum: String
        var maximumText: String
        var externalRef: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, maximumText: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.maximumText = maximumText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCredentialManifestView(_ item: PendingCredentialManifest) -> PendingCredentialManifestView {
        return PendingCredentialManifestView(
            code: item.code,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            maximumText: String(format: "%.2f", item.maximum),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCredentialManifestViews(_ items: [PendingCredentialManifest]) -> [PendingCredentialManifestView] {
        var views: [PendingCredentialManifestView] = []
        for item in items {
            views.append(toPendingCredentialManifestView(item))
        }
        return views
    }

    static func sumPendingCredentialManifestView(_ view: PendingCredentialManifestView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMinimum + parsedMaximum
    }
}
