import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result preference.
    final class ResultPreferenceView {
        var codeText: String
        var title: String
        var createdAt: String
        var channel: String
        var timezone: String
        var activeText: String
        var acuity: String
        var version: String
        var localeText: String
        var statusLabel: String

        init(codeText: String, title: String, createdAt: String, channel: String, timezone: String, activeText: String, acuity: String, version: String, localeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.createdAt = createdAt
            self.channel = channel
            self.timezone = timezone
            self.activeText = activeText
            self.acuity = acuity
            self.version = version
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toResultPreferenceView(_ item: ResultPreference) -> ResultPreferenceView {
        return ResultPreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            createdAt: String(item.createdAt),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            activeText: "\(item.active)",
            acuity: String(item.acuity),
            version: String(item.version),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultPreferenceViews(_ items: [ResultPreference]) -> [ResultPreferenceView] {
        var views: [ResultPreferenceView] = []
        for item in items {
            views.append(toResultPreferenceView(item))
        }
        return views
    }

    static func sumResultPreferenceView(_ view: ResultPreferenceView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedAcuity) + Double(parsedVersion)
    }
}
