import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility bundle.
    final class EligibilityBundleView {
        var code: String
        var title: String
        var sequence: String
        var priority: String
        var cost: String
        var ownerID: String
        var statusLabel: String

        init(code: String, title: String, sequence: String, priority: String, cost: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.priority = priority
            self.cost = cost
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityBundleView(_ item: EligibilityBundle) -> EligibilityBundleView {
        return EligibilityBundleView(
            code: item.code,
            title: item.title,
            sequence: String(item.sequence),
            priority: String(item.priority),
            cost: String(format: "%.2f", item.cost),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityBundleViews(_ items: [EligibilityBundle]) -> [EligibilityBundleView] {
        var views: [EligibilityBundleView] = []
        for item in items {
            views.append(toEligibilityBundleView(item))
        }
        return views
    }

    static func sumEligibilityBundleView(_ view: EligibilityBundleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedSequence) + Double(parsedPriority) + parsedCost
    }
}
