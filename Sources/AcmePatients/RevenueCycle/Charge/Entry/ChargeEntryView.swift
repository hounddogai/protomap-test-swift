import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge entry.
    final class ChargeEntryView {
        var codeText: String
        var labelText: String
        var endsAtText: String
        var priority: String
        var score: String
        var maximumText: String
        var timezone: String
        var archivedText: String
        var retriesText: String
        var version: String
        var statusLabel: String

        init(codeText: String, labelText: String, endsAtText: String, priority: String, score: String, maximumText: String, timezone: String, archivedText: String, retriesText: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.endsAtText = endsAtText
            self.priority = priority
            self.score = score
            self.maximumText = maximumText
            self.timezone = timezone
            self.archivedText = archivedText
            self.retriesText = retriesText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toChargeEntryView(_ item: ChargeEntry) -> ChargeEntryView {
        return ChargeEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            endsAtText: String(item.endsAt),
            priority: String(item.priority),
            score: String(format: "%.2f", item.score),
            maximumText: String(format: "%.2f", item.maximum),
            timezone: item.timezone,
            archivedText: "\(item.archived)",
            retriesText: String(item.retries),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeEntryViews(_ items: [ChargeEntry]) -> [ChargeEntryView] {
        var views: [ChargeEntryView] = []
        for item in items {
            views.append(toChargeEntryView(item))
        }
        return views
    }

    static func sumChargeEntryView(_ view: ChargeEntryView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedPriority) + parsedScore
    }
}
