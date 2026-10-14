import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen tier.
    final class SpecimenTierView {
        var code: String
        var label: String
        var capacity: String
        var categoryText: String
        var createdAtText: String
        var budget: String
        var channel: String
        var clinicianID: String
        var archivedText: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, categoryText: String, createdAtText: String, budget: String, channel: String, clinicianID: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.categoryText = categoryText
            self.createdAtText = createdAtText
            self.budget = budget
            self.channel = channel
            self.clinicianID = clinicianID
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenTierView(_ item: SpecimenTier) -> SpecimenTierView {
        return SpecimenTierView(
            code: item.code,
            label: item.label,
            capacity: String(item.capacity),
            categoryText: item.category,
            createdAtText: String(item.createdAt),
            budget: String(format: "%.2f", item.budget),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            clinicianID: item.clinicianID,
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenTierViews(_ items: [SpecimenTier]) -> [SpecimenTierView] {
        var views: [SpecimenTierView] = []
        for item in items {
            views.append(toSpecimenTierView(item))
        }
        return views
    }

    static func sumSpecimenTierView(_ view: SpecimenTierView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCapacity) + Double(parsedCreatedAt) + parsedBudget
    }
}
