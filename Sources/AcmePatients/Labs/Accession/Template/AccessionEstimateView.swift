import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession estimate.
    final class AccessionEstimateView {
        var code: String
        var label: String
        var ceiling: String
        var refills: String
        var priority: String
        var expiresAt: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, refills: String, priority: String, expiresAt: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.refills = refills
            self.priority = priority
            self.expiresAt = expiresAt
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionEstimateView(_ item: AccessionEstimate) -> AccessionEstimateView {
        return AccessionEstimateView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            ceiling: String(format: "%.2f", item.ceiling),
            refills: String(item.refills),
            priority: String(item.priority),
            expiresAt: String(item.expiresAt),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionEstimateViews(_ items: [AccessionEstimate]) -> [AccessionEstimateView] {
        var views: [AccessionEstimateView] = []
        for item in items {
            views.append(toAccessionEstimateView(item))
        }
        return views
    }

    static func sumAccessionEstimateView(_ view: AccessionEstimateView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedCeiling + Double(parsedRefills) + Double(parsedPriority)
    }
}
