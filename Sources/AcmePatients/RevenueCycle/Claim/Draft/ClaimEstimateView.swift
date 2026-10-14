import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim estimate.
    final class ClaimEstimateView {
        var codeText: String
        var title: String
        var unit: String
        var expiresAt: String
        var retries: String
        var capacity: String
        var budget: String
        var statusLabel: String

        init(codeText: String, title: String, unit: String, expiresAt: String, retries: String, capacity: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.unit = unit
            self.expiresAt = expiresAt
            self.retries = retries
            self.capacity = capacity
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toClaimEstimateView(_ item: ClaimEstimate) -> ClaimEstimateView {
        return ClaimEstimateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            unit: item.unit,
            expiresAt: String(item.expiresAt),
            retries: String(item.retries),
            capacity: String(item.capacity),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimEstimateViews(_ items: [ClaimEstimate]) -> [ClaimEstimateView] {
        var views: [ClaimEstimateView] = []
        for item in items {
            views.append(toClaimEstimateView(item))
        }
        return views
    }

    static func sumClaimEstimateView(_ view: ClaimEstimateView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedRetries) + Double(parsedCapacity)
    }
}
