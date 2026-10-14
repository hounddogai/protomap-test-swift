import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling cleaning entry.
    final class RollingCleaningEntryView {
        var code: String
        var labelText: String
        var sequence: String
        var ceilingText: String
        var payer: String
        var retries: String
        var updatedAt: String
        var category: String
        var priority: String
        var statusLabel: String

        init(code: String, labelText: String, sequence: String, ceilingText: String, payer: String, retries: String, updatedAt: String, category: String, priority: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.sequence = sequence
            self.ceilingText = ceilingText
            self.payer = payer
            self.retries = retries
            self.updatedAt = updatedAt
            self.category = category
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCleaningEntryView(_ item: RollingCleaningEntry) -> RollingCleaningEntryView {
        return RollingCleaningEntryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            sequence: String(item.sequence),
            ceilingText: String(format: "%.2f", item.ceiling),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            retries: String(item.retries),
            updatedAt: String(item.updatedAt),
            category: item.category,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCleaningEntryViews(_ items: [RollingCleaningEntry]) -> [RollingCleaningEntryView] {
        var views: [RollingCleaningEntryView] = []
        for item in items {
            views.append(toRollingCleaningEntryView(item))
        }
        return views
    }

    static func sumRollingCleaningEntryView(_ view: RollingCleaningEntryView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedSequence) + parsedCeiling + Double(parsedRetries)
    }
}
