import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary substitution bundle.
    final class PrimarySubstitutionBundleView {
        var codeText: String
        var name: String
        var checksum: String
        var retries: String
        var version: String
        var statusLabel: String

        init(codeText: String, name: String, checksum: String, retries: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.checksum = checksum
            self.retries = retries
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySubstitutionBundleView(_ item: PrimarySubstitutionBundle) -> PrimarySubstitutionBundleView {
        return PrimarySubstitutionBundleView(
            codeText: item.code,
            name: item.name,
            checksum: item.checksum,
            retries: String(item.retries),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySubstitutionBundleViews(_ items: [PrimarySubstitutionBundle]) -> [PrimarySubstitutionBundleView] {
        var views: [PrimarySubstitutionBundleView] = []
        for item in items {
            views.append(toPrimarySubstitutionBundleView(item))
        }
        return views
    }

    static func sumPrimarySubstitutionBundleView(_ view: PrimarySubstitutionBundleView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRetries) + Double(parsedVersion)
    }
}
