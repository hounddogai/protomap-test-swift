import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional credential claim.
    final class RegionalCredentialClaimView {
        var code: String
        var labelText: String
        var rate: String
        var procedureCode: String
        var threshold: String
        var reviewerText: String
        var descriptionText: String
        var allergyText: String
        var phoneText: String
        var graceDays: String
        var quantity: String
        var statusLabel: String

        init(code: String, labelText: String, rate: String, procedureCode: String, threshold: String, reviewerText: String, descriptionText: String, allergyText: String, phoneText: String, graceDays: String, quantity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.rate = rate
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.reviewerText = reviewerText
            self.descriptionText = descriptionText
            self.allergyText = allergyText
            self.phoneText = phoneText
            self.graceDays = graceDays
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCredentialClaimView(_ item: RegionalCredentialClaim) -> RegionalCredentialClaimView {
        return RegionalCredentialClaimView(
            code: item.code,
            labelText: item.label,
            rate: String(format: "%.2f", item.rate),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            reviewerText: item.reviewer,
            descriptionText: item.description,
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            phoneText: item.phone,
            graceDays: String(item.graceDays),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCredentialClaimViews(_ items: [RegionalCredentialClaim]) -> [RegionalCredentialClaimView] {
        var views: [RegionalCredentialClaimView] = []
        for item in items {
            views.append(toRegionalCredentialClaimView(item))
        }
        return views
    }

    static func sumRegionalCredentialClaimView(_ view: RegionalCredentialClaimView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedRate + parsedThreshold + Double(parsedGraceDays)
    }
}
