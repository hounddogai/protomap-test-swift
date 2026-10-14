import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling consent form segment.
    final class RollingConsentFormSegmentView {
        var code: String
        var label: String
        var checksum: String
        var revisionText: String
        var title: String
        var nameText: String
        var categoryText: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, revisionText: String, title: String, nameText: String, categoryText: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.revisionText = revisionText
            self.title = title
            self.nameText = nameText
            self.categoryText = categoryText
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toRollingConsentFormSegmentView(_ item: RollingConsentFormSegment) -> RollingConsentFormSegmentView {
        return RollingConsentFormSegmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            checksum: item.checksum,
            revisionText: String(item.revision),
            title: item.title,
            nameText: item.name,
            categoryText: item.category,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingConsentFormSegmentViews(_ items: [RollingConsentFormSegment]) -> [RollingConsentFormSegmentView] {
        var views: [RollingConsentFormSegmentView] = []
        for item in items {
            views.append(toRollingConsentFormSegmentView(item))
        }
        return views
    }

    static func sumRollingConsentFormSegmentView(_ view: RollingConsentFormSegmentView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
