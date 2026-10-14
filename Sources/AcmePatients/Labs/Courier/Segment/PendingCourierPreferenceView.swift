import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending courier preference.
    final class PendingCourierPreferenceView {
        var code: String
        var label: String
        var description: String
        var expiresAtText: String
        var limitText: String
        var statusLabel: String

        init(code: String, label: String, description: String, expiresAtText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.description = description
            self.expiresAtText = expiresAtText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCourierPreferenceView(_ item: PendingCourierPreference) -> PendingCourierPreferenceView {
        return PendingCourierPreferenceView(
            code: item.code,
            label: item.label,
            description: Kit.Text.truncate(item.description, limit: 64),
            expiresAtText: String(item.expiresAt),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCourierPreferenceViews(_ items: [PendingCourierPreference]) -> [PendingCourierPreferenceView] {
        var views: [PendingCourierPreferenceView] = []
        for item in items {
            views.append(toPendingCourierPreferenceView(item))
        }
        return views
    }

    static func sumPendingCourierPreferenceView(_ view: PendingCourierPreferenceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedLimit)
    }
}
