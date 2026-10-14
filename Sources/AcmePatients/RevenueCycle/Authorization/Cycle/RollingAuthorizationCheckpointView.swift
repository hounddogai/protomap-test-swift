import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling authorization checkpoint.
    final class RollingAuthorizationCheckpointView {
        var code: String
        var name: String
        var attemptsText: String
        var cost: String
        var visitMinutes: String
        var notes: String
        var marginText: String
        var category: String
        var sequence: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, name: String, attemptsText: String, cost: String, visitMinutes: String, notes: String, marginText: String, category: String, sequence: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attemptsText = attemptsText
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.marginText = marginText
            self.category = category
            self.sequence = sequence
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAuthorizationCheckpointView(_ item: RollingAuthorizationCheckpoint) -> RollingAuthorizationCheckpointView {
        return RollingAuthorizationCheckpointView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            attemptsText: String(item.attempts),
            cost: String(format: "%.2f", item.cost),
            visitMinutes: String(item.visitMinutes),
            notes: item.notes,
            marginText: String(format: "%.2f", item.margin),
            category: item.category,
            sequence: String(item.sequence),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAuthorizationCheckpointViews(_ items: [RollingAuthorizationCheckpoint]) -> [RollingAuthorizationCheckpointView] {
        var views: [RollingAuthorizationCheckpointView] = []
        for item in items {
            views.append(toRollingAuthorizationCheckpointView(item))
        }
        return views
    }

    static func sumRollingAuthorizationCheckpointView(_ view: RollingAuthorizationCheckpointView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAttempts) + parsedCost + Double(parsedVisitMinutes)
    }
}
