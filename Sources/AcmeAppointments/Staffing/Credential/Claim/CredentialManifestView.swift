import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential manifest.
    final class CredentialManifestView {
        var code: String
        var name: String
        var revision: String
        var facility: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, revision: String, facility: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.facility = facility
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialManifestView(_ item: CredentialManifest) -> CredentialManifestView {
        return CredentialManifestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 40),
            revision: String(item.revision),
            facility: item.facility,
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialManifestViews(_ items: [CredentialManifest]) -> [CredentialManifestView] {
        var views: [CredentialManifestView] = []
        for item in items {
            views.append(toCredentialManifestView(item))
        }
        return views
    }

    static func sumCredentialManifestView(_ view: CredentialManifestView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
