import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool claim.
    final class FloatPoolClaimView {
        var code: String
        var label: String
        var createdAt: String
        var approved: String
        var countryText: String
        var activeText: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, approved: String, countryText: String, activeText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.approved = approved
            self.countryText = countryText
            self.activeText = activeText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolClaimView(_ item: FloatPoolClaim) -> FloatPoolClaimView {
        return FloatPoolClaimView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            approved: "\(item.approved)",
            countryText: item.country,
            activeText: "\(item.active)",
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolClaimViews(_ items: [FloatPoolClaim]) -> [FloatPoolClaimView] {
        var views: [FloatPoolClaimView] = []
        for item in items {
            views.append(toFloatPoolClaimView(item))
        }
        return views
    }

    static func sumFloatPoolClaimView(_ view: FloatPoolClaimView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCreatedAt) + parsedMinimum
    }
}
