import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient inventory group.
    final class LenientInventoryGroupView {
        var code: String
        var title: String
        var refills: String
        var segmentText: String
        var externalRef: String
        var pinned: String
        var descriptionText: String
        var allergy: String
        var summary: String
        var specialtyText: String
        var source: String
        var statusLabel: String

        init(code: String, title: String, refills: String, segmentText: String, externalRef: String, pinned: String, descriptionText: String, allergy: String, summary: String, specialtyText: String, source: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refills = refills
            self.segmentText = segmentText
            self.externalRef = externalRef
            self.pinned = pinned
            self.descriptionText = descriptionText
            self.allergy = allergy
            self.summary = summary
            self.specialtyText = specialtyText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInventoryGroupView(_ item: LenientInventoryGroup) -> LenientInventoryGroupView {
        return LenientInventoryGroupView(
            code: item.code,
            title: item.title,
            refills: String(item.refills),
            segmentText: Kit.Text.truncate(item.segment, limit: 80),
            externalRef: item.externalRef,
            pinned: "\(item.pinned)",
            descriptionText: item.description,
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 64),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInventoryGroupViews(_ items: [LenientInventoryGroup]) -> [LenientInventoryGroupView] {
        var views: [LenientInventoryGroupView] = []
        for item in items {
            views.append(toLenientInventoryGroupView(item))
        }
        return views
    }

    static func sumLenientInventoryGroupView(_ view: LenientInventoryGroupView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
