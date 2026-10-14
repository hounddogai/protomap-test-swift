import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall override.
    final class RecallOverrideView {
        var codeText: String
        var name: String
        var timezone: String
        var endsAt: String
        var visible: String
        var statusLabel: String

        init(codeText: String, name: String, timezone: String, endsAt: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.timezone = timezone
            self.endsAt = endsAt
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toRecallOverrideView(_ item: RecallOverride) -> RecallOverrideView {
        return RecallOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            timezone: item.timezone,
            endsAt: String(item.endsAt),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallOverrideViews(_ items: [RecallOverride]) -> [RecallOverrideView] {
        var views: [RecallOverrideView] = []
        for item in items {
            views.append(toRecallOverrideView(item))
        }
        return views
    }

    static func sumRecallOverrideView(_ view: RecallOverrideView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
