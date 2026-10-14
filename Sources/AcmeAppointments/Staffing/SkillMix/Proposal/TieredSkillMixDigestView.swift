import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered skill mix digest.
    final class TieredSkillMixDigestView {
        var code: String
        var labelText: String
        var approved: String
        var category: String
        var margin: String
        var startsAt: String
        var createdAtText: String
        var endsAt: String
        var title: String
        var visitMinutes: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, labelText: String, approved: String, category: String, margin: String, startsAt: String, createdAtText: String, endsAt: String, title: String, visitMinutes: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approved = approved
            self.category = category
            self.margin = margin
            self.startsAt = startsAt
            self.createdAtText = createdAtText
            self.endsAt = endsAt
            self.title = title
            self.visitMinutes = visitMinutes
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSkillMixDigestView(_ item: TieredSkillMixDigest) -> TieredSkillMixDigestView {
        return TieredSkillMixDigestView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            approved: "\(item.approved)",
            category: item.category,
            margin: String(format: "%.2f", item.margin),
            startsAt: String(item.startsAt),
            createdAtText: String(item.createdAt),
            endsAt: String(item.endsAt),
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSkillMixDigestViews(_ items: [TieredSkillMixDigest]) -> [TieredSkillMixDigestView] {
        var views: [TieredSkillMixDigestView] = []
        for item in items {
            views.append(toTieredSkillMixDigestView(item))
        }
        return views
    }

    static func sumTieredSkillMixDigestView(_ view: TieredSkillMixDigestView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedMargin + Double(parsedStartsAt) + Double(parsedCreatedAt)
    }
}
