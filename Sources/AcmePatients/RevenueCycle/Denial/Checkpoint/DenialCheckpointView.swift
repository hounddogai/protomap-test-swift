import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial checkpoint.
    final class DenialCheckpointView {
        var code: String
        var name: String
        var weight: String
        var checksum: String
        var allergyText: String
        var budget: String
        var archivedText: String
        var updatedAt: String
        var summary: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, weight: String, checksum: String, allergyText: String, budget: String, archivedText: String, updatedAt: String, summary: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.checksum = checksum
            self.allergyText = allergyText
            self.budget = budget
            self.archivedText = archivedText
            self.updatedAt = updatedAt
            self.summary = summary
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toDenialCheckpointView(_ item: DenialCheckpoint) -> DenialCheckpointView {
        return DenialCheckpointView(
            code: item.code,
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            checksum: item.checksum,
            allergyText: item.allergy,
            budget: String(format: "%.2f", item.budget),
            archivedText: "\(item.archived)",
            updatedAt: String(item.updatedAt),
            summary: item.summary,
            locale: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialCheckpointViews(_ items: [DenialCheckpoint]) -> [DenialCheckpointView] {
        var views: [DenialCheckpointView] = []
        for item in items {
            views.append(toDenialCheckpointView(item))
        }
        return views
    }

    static func sumDenialCheckpointView(_ view: DenialCheckpointView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedWeight + parsedBudget + Double(parsedUpdatedAt)
    }
}
