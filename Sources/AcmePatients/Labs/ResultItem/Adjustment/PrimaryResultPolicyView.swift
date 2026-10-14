import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary result policy.
    final class PrimaryResultPolicyView {
        var code: String
        var titleText: String
        var locale: String
        var bed: String
        var visible: String
        var description: String
        var endsAt: String
        var activeText: String
        var statusLabel: String

        init(code: String, titleText: String, locale: String, bed: String, visible: String, description: String, endsAt: String, activeText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.locale = locale
            self.bed = bed
            self.visible = visible
            self.description = description
            self.endsAt = endsAt
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryResultPolicyView(_ item: PrimaryResultPolicy) -> PrimaryResultPolicyView {
        return PrimaryResultPolicyView(
            code: item.code,
            titleText: item.title,
            locale: item.locale,
            bed: item.bed,
            visible: "\(item.visible)",
            description: item.description,
            endsAt: String(item.endsAt),
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryResultPolicyViews(_ items: [PrimaryResultPolicy]) -> [PrimaryResultPolicyView] {
        var views: [PrimaryResultPolicyView] = []
        for item in items {
            views.append(toPrimaryResultPolicyView(item))
        }
        return views
    }

    static func sumPrimaryResultPolicyView(_ view: PrimaryResultPolicyView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
