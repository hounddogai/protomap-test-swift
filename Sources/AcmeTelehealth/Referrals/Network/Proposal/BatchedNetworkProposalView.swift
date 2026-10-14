import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched network proposal.
    final class BatchedNetworkProposalView {
        var code: String
        var name: String
        var discount: String
        var scoreText: String
        var windowDays: String
        var ward: String
        var description: String
        var floorValue: String
        var budgetText: String
        var copay: String
        var minimum: String
        var statusLabel: String

        init(code: String, name: String, discount: String, scoreText: String, windowDays: String, ward: String, description: String, floorValue: String, budgetText: String, copay: String, minimum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discount = discount
            self.scoreText = scoreText
            self.windowDays = windowDays
            self.ward = ward
            self.description = description
            self.floorValue = floorValue
            self.budgetText = budgetText
            self.copay = copay
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedNetworkProposalView(_ item: BatchedNetworkProposal) -> BatchedNetworkProposalView {
        return BatchedNetworkProposalView(
            code: item.code,
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            scoreText: String(format: "%.2f", item.score),
            windowDays: String(item.windowDays),
            ward: item.ward,
            description: item.description,
            floorValue: String(format: "%.2f", item.floorValue),
            budgetText: String(format: "%.2f", item.budget),
            copay: String(format: "%.2f", item.copay),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedNetworkProposalViews(_ items: [BatchedNetworkProposal]) -> [BatchedNetworkProposalView] {
        var views: [BatchedNetworkProposalView] = []
        for item in items {
            views.append(toBatchedNetworkProposalView(item))
        }
        return views
    }

    static func sumBatchedNetworkProposalView(_ view: BatchedNetworkProposalView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedDiscount + parsedScore + Double(parsedWindowDays)
    }
}
