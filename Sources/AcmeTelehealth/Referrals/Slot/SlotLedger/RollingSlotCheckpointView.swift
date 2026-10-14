import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling slot checkpoint.
    final class RollingSlotCheckpointView {
        var code: String
        var name: String
        var ward: String
        var sequence: String
        var timezoneText: String
        var budget: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, name: String, ward: String, sequence: String, timezoneText: String, budget: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.sequence = sequence
            self.timezoneText = timezoneText
            self.budget = budget
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSlotCheckpointView(_ item: RollingSlotCheckpoint) -> RollingSlotCheckpointView {
        return RollingSlotCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            ward: item.ward,
            sequence: String(item.sequence),
            timezoneText: item.timezone,
            budget: String(format: "%.2f", item.budget),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSlotCheckpointViews(_ items: [RollingSlotCheckpoint]) -> [RollingSlotCheckpointView] {
        var views: [RollingSlotCheckpointView] = []
        for item in items {
            views.append(toRollingSlotCheckpointView(item))
        }
        return views
    }

    static func sumRollingSlotCheckpointView(_ view: RollingSlotCheckpointView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedSequence) + parsedBudget + Double(parsedUpdatedAt)
    }
}
