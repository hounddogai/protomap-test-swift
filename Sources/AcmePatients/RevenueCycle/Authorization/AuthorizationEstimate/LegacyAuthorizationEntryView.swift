import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy authorization entry.
    final class LegacyAuthorizationEntryView {
        var codeText: String
        var label: String
        var startsAt: String
        var ratio: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, startsAt: String, ratio: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.startsAt = startsAt
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAuthorizationEntryView(_ item: LegacyAuthorizationEntry) -> LegacyAuthorizationEntryView {
        return LegacyAuthorizationEntryView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            startsAt: String(item.startsAt),
            ratio: String(format: "%.2f", item.ratio),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAuthorizationEntryViews(_ items: [LegacyAuthorizationEntry]) -> [LegacyAuthorizationEntryView] {
        var views: [LegacyAuthorizationEntryView] = []
        for item in items {
            views.append(toLegacyAuthorizationEntryView(item))
        }
        return views
    }

    static func sumLegacyAuthorizationEntryView(_ view: LegacyAuthorizationEntryView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedStartsAt) + parsedRatio + Double(parsedVisitMinutes)
    }
}
