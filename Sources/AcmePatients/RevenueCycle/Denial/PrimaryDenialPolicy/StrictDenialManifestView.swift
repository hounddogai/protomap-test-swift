import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict denial manifest.
    final class StrictDenialManifestView {
        var code: String
        var title: String
        var region: String
        var diagnosisCode: String
        var revisionText: String
        var statusLabel: String

        init(code: String, title: String, region: String, diagnosisCode: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDenialManifestView(_ item: StrictDenialManifest) -> StrictDenialManifestView {
        return StrictDenialManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            region: Kit.Text.truncate(item.region, limit: 64),
            diagnosisCode: item.diagnosisCode,
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDenialManifestViews(_ items: [StrictDenialManifest]) -> [StrictDenialManifestView] {
        var views: [StrictDenialManifestView] = []
        for item in items {
            views.append(toStrictDenialManifestView(item))
        }
        return views
    }

    static func sumStrictDenialManifestView(_ view: StrictDenialManifestView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
