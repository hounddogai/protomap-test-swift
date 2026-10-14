import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation manifest.
    final class RevocationManifestView {
        var codeText: String
        var titleText: String
        var phone: String
        var reviewer: String
        var pinned: String
        var patientRefText: String
        var maximum: String
        var segment: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, titleText: String, phone: String, reviewer: String, pinned: String, patientRefText: String, maximum: String, segment: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.phone = phone
            self.reviewer = reviewer
            self.pinned = pinned
            self.patientRefText = patientRefText
            self.maximum = maximum
            self.segment = segment
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationManifestView(_ item: RevocationManifest) -> RevocationManifestView {
        return RevocationManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            phone: item.phone,
            reviewer: item.reviewer,
            pinned: "\(item.pinned)",
            patientRefText: item.patientRef,
            maximum: String(format: "%.2f", item.maximum),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationManifestViews(_ items: [RevocationManifest]) -> [RevocationManifestView] {
        var views: [RevocationManifestView] = []
        for item in items {
            views.append(toRevocationManifestView(item))
        }
        return views
    }

    static func sumRevocationManifestView(_ view: RevocationManifestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt)
    }
}
