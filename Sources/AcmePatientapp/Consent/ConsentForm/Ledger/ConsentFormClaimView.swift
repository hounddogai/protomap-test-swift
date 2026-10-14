import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form claim.
    final class ConsentFormClaimView {
        var code: String
        var labelText: String
        var visitMinutes: String
        var categoryText: String
        var updatedAt: String
        var version: String
        var externalRef: String
        var windowDays: String
        var quantityText: String
        var budget: String
        var statusLabel: String

        init(code: String, labelText: String, visitMinutes: String, categoryText: String, updatedAt: String, version: String, externalRef: String, windowDays: String, quantityText: String, budget: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.visitMinutes = visitMinutes
            self.categoryText = categoryText
            self.updatedAt = updatedAt
            self.version = version
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.quantityText = quantityText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormClaimView(_ item: ConsentFormClaim) -> ConsentFormClaimView {
        return ConsentFormClaimView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            visitMinutes: String(item.visitMinutes),
            categoryText: item.category,
            updatedAt: String(item.updatedAt),
            version: String(item.version),
            externalRef: item.externalRef,
            windowDays: String(item.windowDays),
            quantityText: String(item.quantity),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormClaimViews(_ items: [ConsentFormClaim]) -> [ConsentFormClaimView] {
        var views: [ConsentFormClaimView] = []
        for item in items {
            views.append(toConsentFormClaimView(item))
        }
        return views
    }

    static func sumConsentFormClaimView(_ view: ConsentFormClaimView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedUpdatedAt) + Double(parsedVersion)
    }
}
