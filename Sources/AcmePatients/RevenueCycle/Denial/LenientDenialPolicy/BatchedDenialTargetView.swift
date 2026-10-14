import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched denial target.
    final class BatchedDenialTargetView {
        var codeText: String
        var nameText: String
        var limitText: String
        var attempts: String
        var ceilingText: String
        var graceDays: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, nameText: String, limitText: String, attempts: String, ceilingText: String, graceDays: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.limitText = limitText
            self.attempts = attempts
            self.ceilingText = ceilingText
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDenialTargetView(_ item: BatchedDenialTarget) -> BatchedDenialTargetView {
        return BatchedDenialTargetView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            limitText: String(item.limit),
            attempts: String(item.attempts),
            ceilingText: String(format: "%.2f", item.ceiling),
            graceDays: String(item.graceDays),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDenialTargetViews(_ items: [BatchedDenialTarget]) -> [BatchedDenialTargetView] {
        var views: [BatchedDenialTargetView] = []
        for item in items {
            views.append(toBatchedDenialTargetView(item))
        }
        return views
    }

    static func sumBatchedDenialTargetView(_ view: BatchedDenialTargetView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedLimit) + Double(parsedAttempts) + parsedCeiling
    }
}
