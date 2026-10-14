import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending skill mix digest.
    final class PendingSkillMixDigestView {
        var code: String
        var title: String
        var discountText: String
        var encounterID: String
        var notes: String
        var ceiling: String
        var revision: String
        var threshold: String
        var statusLabel: String

        init(code: String, title: String, discountText: String, encounterID: String, notes: String, ceiling: String, revision: String, threshold: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discountText = discountText
            self.encounterID = encounterID
            self.notes = notes
            self.ceiling = ceiling
            self.revision = revision
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toPendingSkillMixDigestView(_ item: PendingSkillMixDigest) -> PendingSkillMixDigestView {
        return PendingSkillMixDigestView(
            code: item.code,
            title: item.title,
            discountText: String(format: "%.2f", item.discount),
            encounterID: item.encounterID,
            notes: item.notes,
            ceiling: String(format: "%.2f", item.ceiling),
            revision: String(item.revision),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingSkillMixDigestViews(_ items: [PendingSkillMixDigest]) -> [PendingSkillMixDigestView] {
        var views: [PendingSkillMixDigestView] = []
        for item in items {
            views.append(toPendingSkillMixDigestView(item))
        }
        return views
    }

    static func sumPendingSkillMixDigestView(_ view: PendingSkillMixDigestView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedDiscount + parsedCeiling + Double(parsedRevision)
    }
}
