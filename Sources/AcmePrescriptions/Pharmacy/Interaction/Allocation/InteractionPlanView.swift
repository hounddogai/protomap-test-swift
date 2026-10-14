import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction plan.
    final class InteractionPlanView {
        var code: String
        var name: String
        var descriptionText: String
        var threshold: String
        var checksum: String
        var ward: String
        var categoryText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, descriptionText: String, threshold: String, checksum: String, ward: String, categoryText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.descriptionText = descriptionText
            self.threshold = threshold
            self.checksum = checksum
            self.ward = ward
            self.categoryText = categoryText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionPlanView(_ item: InteractionPlan) -> InteractionPlanView {
        return InteractionPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            descriptionText: item.description,
            threshold: String(format: "%.2f", item.threshold),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            categoryText: item.category,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionPlanViews(_ items: [InteractionPlan]) -> [InteractionPlanView] {
        var views: [InteractionPlanView] = []
        for item in items {
            views.append(toInteractionPlanView(item))
        }
        return views
    }

    static func sumInteractionPlanView(_ view: InteractionPlanView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedThreshold + Double(parsedExpiresAt)
    }
}
