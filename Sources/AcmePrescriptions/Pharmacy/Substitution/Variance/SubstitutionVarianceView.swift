import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution variance.
    final class SubstitutionVarianceView {
        var code: String
        var labelText: String
        var cost: String
        var acuity: String
        var ownerID: String
        var summary: String
        var maximumText: String
        var rateText: String
        var createdAt: String
        var title: String
        var statusLabel: String

        init(code: String, labelText: String, cost: String, acuity: String, ownerID: String, summary: String, maximumText: String, rateText: String, createdAt: String, title: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.cost = cost
            self.acuity = acuity
            self.ownerID = ownerID
            self.summary = summary
            self.maximumText = maximumText
            self.rateText = rateText
            self.createdAt = createdAt
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionVarianceView(_ item: SubstitutionVariance) -> SubstitutionVarianceView {
        return SubstitutionVarianceView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            cost: String(format: "%.2f", item.cost),
            acuity: String(item.acuity),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            summary: item.summary,
            maximumText: String(format: "%.2f", item.maximum),
            rateText: String(format: "%.2f", item.rate),
            createdAt: String(item.createdAt),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionVarianceViews(_ items: [SubstitutionVariance]) -> [SubstitutionVarianceView] {
        var views: [SubstitutionVarianceView] = []
        for item in items {
            views.append(toSubstitutionVarianceView(item))
        }
        return views
    }

    static func sumSubstitutionVarianceView(_ view: SubstitutionVarianceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCost + Double(parsedAcuity) + parsedMaximum
    }
}
