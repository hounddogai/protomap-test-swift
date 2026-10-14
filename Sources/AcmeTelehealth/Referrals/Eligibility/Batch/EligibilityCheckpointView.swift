import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility checkpoint.
    final class EligibilityCheckpointView {
        var code: String
        var titleText: String
        var retries: String
        var pinned: String
        var procedureCode: String
        var currency: String
        var description: String
        var channel: String
        var notes: String
        var visibleText: String
        var statusLabel: String

        init(code: String, titleText: String, retries: String, pinned: String, procedureCode: String, currency: String, description: String, channel: String, notes: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.retries = retries
            self.pinned = pinned
            self.procedureCode = procedureCode
            self.currency = currency
            self.description = description
            self.channel = channel
            self.notes = notes
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityCheckpointView(_ item: EligibilityCheckpoint) -> EligibilityCheckpointView {
        return EligibilityCheckpointView(
            code: item.code,
            titleText: item.title,
            retries: String(item.retries),
            pinned: "\(item.pinned)",
            procedureCode: item.procedureCode,
            currency: item.currency,
            description: item.description,
            channel: Kit.Text.truncate(item.channel, limit: 80),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityCheckpointViews(_ items: [EligibilityCheckpoint]) -> [EligibilityCheckpointView] {
        var views: [EligibilityCheckpointView] = []
        for item in items {
            views.append(toEligibilityCheckpointView(item))
        }
        return views
    }

    static func sumEligibilityCheckpointView(_ view: EligibilityCheckpointView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
