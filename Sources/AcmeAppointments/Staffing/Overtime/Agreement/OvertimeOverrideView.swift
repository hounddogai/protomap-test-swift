import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime override.
    final class OvertimeOverrideView {
        var code: String
        var name: String
        var notesText: String
        var channelText: String
        var payer: String
        var endsAt: String
        var locale: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, notesText: String, channelText: String, payer: String, endsAt: String, locale: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.notesText = notesText
            self.channelText = channelText
            self.payer = payer
            self.endsAt = endsAt
            self.locale = locale
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeOverrideView(_ item: OvertimeOverride) -> OvertimeOverrideView {
        return OvertimeOverrideView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            notesText: item.notes,
            channelText: item.channel,
            payer: item.payer,
            endsAt: String(item.endsAt),
            locale: item.locale,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeOverrideViews(_ items: [OvertimeOverride]) -> [OvertimeOverrideView] {
        var views: [OvertimeOverrideView] = []
        for item in items {
            views.append(toOvertimeOverrideView(item))
        }
        return views
    }

    static func sumOvertimeOverrideView(_ view: OvertimeOverrideView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCreatedAt)
    }
}
