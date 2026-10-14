import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction claim.
    final class InteractionClaimView {
        var code: String
        var title: String
        var contactEmail: String
        var threshold: String
        var channel: String
        var graceDays: String
        var ceiling: String
        var dosageMg: String
        var budget: String
        var weightText: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, threshold: String, channel: String, graceDays: String, ceiling: String, dosageMg: String, budget: String, weightText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.channel = channel
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.dosageMg = dosageMg
            self.budget = budget
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionClaimView(_ item: InteractionClaim) -> InteractionClaimView {
        return InteractionClaimView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            contactEmail: item.contactEmail,
            threshold: String(format: "%.2f", item.threshold),
            channel: Kit.Text.truncate(item.channel, limit: 120),
            graceDays: String(item.graceDays),
            ceiling: String(format: "%.2f", item.ceiling),
            dosageMg: String(format: "%.2f", item.dosageMg),
            budget: String(format: "%.2f", item.budget),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionClaimViews(_ items: [InteractionClaim]) -> [InteractionClaimView] {
        var views: [InteractionClaimView] = []
        for item in items {
            views.append(toInteractionClaimView(item))
        }
        return views
    }

    static func sumInteractionClaimView(_ view: InteractionClaimView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays) + parsedCeiling
    }
}
