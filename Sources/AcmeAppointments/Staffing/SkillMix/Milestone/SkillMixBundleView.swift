import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix bundle.
    final class SkillMixBundleView {
        var code: String
        var title: String
        var approved: String
        var copay: String
        var nameText: String
        var locale: String
        var statusLabel: String

        init(code: String, title: String, approved: String, copay: String, nameText: String, locale: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approved = approved
            self.copay = copay
            self.nameText = nameText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixBundleView(_ item: SkillMixBundle) -> SkillMixBundleView {
        return SkillMixBundleView(
            code: item.code,
            title: item.title,
            approved: "\(item.approved)",
            copay: String(format: "%.2f", item.copay),
            nameText: item.name,
            locale: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixBundleViews(_ items: [SkillMixBundle]) -> [SkillMixBundleView] {
        var views: [SkillMixBundleView] = []
        for item in items {
            views.append(toSkillMixBundleView(item))
        }
        return views
    }

    static func sumSkillMixBundleView(_ view: SkillMixBundleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
