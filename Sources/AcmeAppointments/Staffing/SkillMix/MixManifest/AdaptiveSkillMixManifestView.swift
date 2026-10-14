import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive skill mix manifest.
    final class AdaptiveSkillMixManifestView {
        var code: String
        var title: String
        var endsAt: String
        var nameText: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, endsAt: String, nameText: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.nameText = nameText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveSkillMixManifestView(_ item: AdaptiveSkillMixManifest) -> AdaptiveSkillMixManifestView {
        return AdaptiveSkillMixManifestView(
            code: item.code,
            title: item.title,
            endsAt: String(item.endsAt),
            nameText: item.name,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveSkillMixManifestViews(_ items: [AdaptiveSkillMixManifest]) -> [AdaptiveSkillMixManifestView] {
        var views: [AdaptiveSkillMixManifestView] = []
        for item in items {
            views.append(toAdaptiveSkillMixManifestView(item))
        }
        return views
    }

    static func sumAdaptiveSkillMixManifestView(_ view: AdaptiveSkillMixManifestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
