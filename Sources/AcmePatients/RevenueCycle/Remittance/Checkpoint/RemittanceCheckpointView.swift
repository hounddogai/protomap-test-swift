import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance checkpoint.
    final class RemittanceCheckpointView {
        var code: String
        var label: String
        var attempts: String
        var startsAt: String
        var categoryText: String
        var ratio: String
        var statusLabel: String

        init(code: String, label: String, attempts: String, startsAt: String, categoryText: String, ratio: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.startsAt = startsAt
            self.categoryText = categoryText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceCheckpointView(_ item: RemittanceCheckpoint) -> RemittanceCheckpointView {
        return RemittanceCheckpointView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            attempts: String(item.attempts),
            startsAt: String(item.startsAt),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceCheckpointViews(_ items: [RemittanceCheckpoint]) -> [RemittanceCheckpointView] {
        var views: [RemittanceCheckpointView] = []
        for item in items {
            views.append(toRemittanceCheckpointView(item))
        }
        return views
    }

    static func sumRemittanceCheckpointView(_ view: RemittanceCheckpointView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAttempts) + Double(parsedStartsAt) + parsedRatio
    }
}
