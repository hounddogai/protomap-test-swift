import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default disclosure profile.
    final class DefaultDisclosureProfileView {
        var code: String
        var label: String
        var updatedAt: String
        var channel: String
        var titleText: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, channel: String, titleText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.channel = channel
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDisclosureProfileView(_ item: DefaultDisclosureProfile) -> DefaultDisclosureProfileView {
        return DefaultDisclosureProfileView(
            code: item.code,
            label: item.label,
            updatedAt: String(item.updatedAt),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            titleText: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDisclosureProfileViews(_ items: [DefaultDisclosureProfile]) -> [DefaultDisclosureProfileView] {
        var views: [DefaultDisclosureProfileView] = []
        for item in items {
            views.append(toDefaultDisclosureProfileView(item))
        }
        return views
    }

    static func sumDefaultDisclosureProfileView(_ view: DefaultDisclosureProfileView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
