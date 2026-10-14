import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot manifest.
    final class SlotManifestView {
        var codeText: String
        var name: String
        var revision: String
        var ceiling: String
        var title: String
        var currency: String
        var locale: String
        var active: String
        var cost: String
        var threshold: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, name: String, revision: String, ceiling: String, title: String, currency: String, locale: String, active: String, cost: String, threshold: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.revision = revision
            self.ceiling = ceiling
            self.title = title
            self.currency = currency
            self.locale = locale
            self.active = active
            self.cost = cost
            self.threshold = threshold
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotManifestView(_ item: SlotManifest) -> SlotManifestView {
        return SlotManifestView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            revision: String(item.revision),
            ceiling: String(format: "%.2f", item.ceiling),
            title: Kit.Text.truncate(item.title, limit: 120),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            locale: item.locale,
            active: "\(item.active)",
            cost: String(format: "%.2f", item.cost),
            threshold: String(format: "%.2f", item.threshold),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotManifestViews(_ items: [SlotManifest]) -> [SlotManifestView] {
        var views: [SlotManifestView] = []
        for item in items {
            views.append(toSlotManifestView(item))
        }
        return views
    }

    static func sumSlotManifestView(_ view: SlotManifestView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRevision) + parsedCeiling + parsedCost
    }
}
