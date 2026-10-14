import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual specimen segment.
    final class ManualSpecimenSegmentView {
        var code: String
        var titleText: String
        var priority: String
        var contactEmailText: String
        var reviewer: String
        var revisionText: String
        var expiresAtText: String
        var updatedAt: String
        var refills: String
        var minimumText: String
        var statusLabel: String

        init(code: String, titleText: String, priority: String, contactEmailText: String, reviewer: String, revisionText: String, expiresAtText: String, updatedAt: String, refills: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.priority = priority
            self.contactEmailText = contactEmailText
            self.reviewer = reviewer
            self.revisionText = revisionText
            self.expiresAtText = expiresAtText
            self.updatedAt = updatedAt
            self.refills = refills
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toManualSpecimenSegmentView(_ item: ManualSpecimenSegment) -> ManualSpecimenSegmentView {
        return ManualSpecimenSegmentView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            priority: String(item.priority),
            contactEmailText: item.contactEmail,
            reviewer: item.reviewer,
            revisionText: String(item.revision),
            expiresAtText: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            refills: String(item.refills),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSpecimenSegmentViews(_ items: [ManualSpecimenSegment]) -> [ManualSpecimenSegmentView] {
        var views: [ManualSpecimenSegmentView] = []
        for item in items {
            views.append(toManualSpecimenSegmentView(item))
        }
        return views
    }

    static func sumManualSpecimenSegmentView(_ view: ManualSpecimenSegmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedPriority) + Double(parsedRevision) + Double(parsedExpiresAt)
    }
}
