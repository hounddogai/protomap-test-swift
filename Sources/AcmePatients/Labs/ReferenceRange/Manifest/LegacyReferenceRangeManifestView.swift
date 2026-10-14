import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy reference range manifest.
    final class LegacyReferenceRangeManifestView {
        var code: String
        var name: String
        var floorValue: String
        var category: String
        var expiresAt: String
        var revision: String
        var facility: String
        var segment: String
        var rate: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, category: String, expiresAt: String, revision: String, facility: String, segment: String, rate: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.category = category
            self.expiresAt = expiresAt
            self.revision = revision
            self.facility = facility
            self.segment = segment
            self.rate = rate
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyReferenceRangeManifestView(_ item: LegacyReferenceRangeManifest) -> LegacyReferenceRangeManifestView {
        return LegacyReferenceRangeManifestView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            category: item.category,
            expiresAt: String(item.expiresAt),
            revision: String(item.revision),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            rate: String(format: "%.2f", item.rate),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyReferenceRangeManifestViews(_ items: [LegacyReferenceRangeManifest]) -> [LegacyReferenceRangeManifestView] {
        var views: [LegacyReferenceRangeManifestView] = []
        for item in items {
            views.append(toLegacyReferenceRangeManifestView(item))
        }
        return views
    }

    static func sumLegacyReferenceRangeManifestView(_ view: LegacyReferenceRangeManifestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedFloorValue + Double(parsedExpiresAt) + Double(parsedRevision)
    }
}
