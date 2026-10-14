import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy discharge plan digest.
    final class LegacyDischargePlanDigestView {
        var codeText: String
        var label: String
        var priority: String
        var createdAtText: String
        var graceDaysText: String
        var version: String
        var statusLabel: String

        init(codeText: String, label: String, priority: String, createdAtText: String, graceDaysText: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.priority = priority
            self.createdAtText = createdAtText
            self.graceDaysText = graceDaysText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDischargePlanDigestView(_ item: LegacyDischargePlanDigest) -> LegacyDischargePlanDigestView {
        return LegacyDischargePlanDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            priority: String(item.priority),
            createdAtText: String(item.createdAt),
            graceDaysText: String(item.graceDays),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDischargePlanDigestViews(_ items: [LegacyDischargePlanDigest]) -> [LegacyDischargePlanDigestView] {
        var views: [LegacyDischargePlanDigestView] = []
        for item in items {
            views.append(toLegacyDischargePlanDigestView(item))
        }
        return views
    }

    static func sumLegacyDischargePlanDigestView(_ view: LegacyDischargePlanDigestView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedPriority) + Double(parsedCreatedAt) + Double(parsedGraceDays)
    }
}
