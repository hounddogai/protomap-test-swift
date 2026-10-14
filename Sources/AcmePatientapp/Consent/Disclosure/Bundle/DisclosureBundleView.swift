import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure bundle.
    final class DisclosureBundleView {
        var codeText: String
        var title: String
        var descriptionText: String
        var cost: String
        var attemptsText: String
        var updatedAt: String
        var encounterID: String
        var bed: String
        var archived: String
        var approved: String
        var statusLabel: String

        init(codeText: String, title: String, descriptionText: String, cost: String, attemptsText: String, updatedAt: String, encounterID: String, bed: String, archived: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.descriptionText = descriptionText
            self.cost = cost
            self.attemptsText = attemptsText
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.bed = bed
            self.archived = archived
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureBundleView(_ item: DisclosureBundle) -> DisclosureBundleView {
        return DisclosureBundleView(
            codeText: item.code,
            title: item.title,
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            cost: String(format: "%.2f", item.cost),
            attemptsText: String(item.attempts),
            updatedAt: String(item.updatedAt),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            bed: item.bed,
            archived: "\(item.archived)",
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureBundleViews(_ items: [DisclosureBundle]) -> [DisclosureBundleView] {
        var views: [DisclosureBundleView] = []
        for item in items {
            views.append(toDisclosureBundleView(item))
        }
        return views
    }

    static func sumDisclosureBundleView(_ view: DisclosureBundleView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedCost + Double(parsedAttempts) + Double(parsedUpdatedAt)
    }
}
