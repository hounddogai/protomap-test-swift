import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted goal entry.
    final class WeightedGoalEntryView {
        var codeText: String
        var name: String
        var version: String
        var ownerID: String
        var limit: String
        var updatedAtText: String
        var retriesText: String
        var ward: String
        var statusLabel: String

        init(codeText: String, name: String, version: String, ownerID: String, limit: String, updatedAtText: String, retriesText: String, ward: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.version = version
            self.ownerID = ownerID
            self.limit = limit
            self.updatedAtText = updatedAtText
            self.retriesText = retriesText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedGoalEntryView(_ item: WeightedGoalEntry) -> WeightedGoalEntryView {
        return WeightedGoalEntryView(
            codeText: item.code,
            name: item.name,
            version: String(item.version),
            ownerID: item.ownerID,
            limit: String(item.limit),
            updatedAtText: String(item.updatedAt),
            retriesText: String(item.retries),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedGoalEntryViews(_ items: [WeightedGoalEntry]) -> [WeightedGoalEntryView] {
        var views: [WeightedGoalEntryView] = []
        for item in items {
            views.append(toWeightedGoalEntryView(item))
        }
        return views
    }

    static func sumWeightedGoalEntryView(_ view: WeightedGoalEntryView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVersion) + Double(parsedLimit) + Double(parsedUpdatedAt)
    }
}
