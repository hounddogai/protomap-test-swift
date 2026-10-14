import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation digest.
    final class IsolationDigestView {
        var code: String
        var title: String
        var cost: String
        var locale: String
        var attempts: String
        var label: String
        var archived: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, title: String, cost: String, locale: String, attempts: String, label: String, archived: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.locale = locale
            self.attempts = attempts
            self.label = label
            self.archived = archived
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationDigestView(_ item: IsolationDigest) -> IsolationDigestView {
        return IsolationDigestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            cost: String(format: "%.2f", item.cost),
            locale: item.locale,
            attempts: String(item.attempts),
            label: item.label,
            archived: "\(item.archived)",
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationDigestViews(_ items: [IsolationDigest]) -> [IsolationDigestView] {
        var views: [IsolationDigestView] = []
        for item in items {
            views.append(toIsolationDigestView(item))
        }
        return views
    }

    static func sumIsolationDigestView(_ view: IsolationDigestView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCost + Double(parsedAttempts)
    }
}
