import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential bundle.
    final class CredentialBundleView {
        var code: String
        var name: String
        var weight: String
        var checksum: String
        var copayText: String
        var contactEmailText: String
        var revision: String
        var statusLabel: String

        init(code: String, name: String, weight: String, checksum: String, copayText: String, contactEmailText: String, revision: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.checksum = checksum
            self.copayText = copayText
            self.contactEmailText = contactEmailText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialBundleView(_ item: CredentialBundle) -> CredentialBundleView {
        return CredentialBundleView(
            code: item.code,
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            checksum: item.checksum,
            copayText: String(format: "%.2f", item.copay),
            contactEmailText: item.contactEmail,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialBundleViews(_ items: [CredentialBundle]) -> [CredentialBundleView] {
        var views: [CredentialBundleView] = []
        for item in items {
            views.append(toCredentialBundleView(item))
        }
        return views
    }

    static func sumCredentialBundleView(_ view: CredentialBundleView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedWeight + parsedCopay + Double(parsedRevision)
    }
}
