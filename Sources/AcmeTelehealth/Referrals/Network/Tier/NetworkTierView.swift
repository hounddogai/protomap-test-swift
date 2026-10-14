import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network tier.
    final class NetworkTierView {
        var code: String
        var titleText: String
        var payer: String
        var capacity: String
        var weight: String
        var budget: String
        var endsAtText: String
        var ratio: String
        var threshold: String
        var floorValue: String
        var acuity: String
        var statusLabel: String

        init(code: String, titleText: String, payer: String, capacity: String, weight: String, budget: String, endsAtText: String, ratio: String, threshold: String, floorValue: String, acuity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.payer = payer
            self.capacity = capacity
            self.weight = weight
            self.budget = budget
            self.endsAtText = endsAtText
            self.ratio = ratio
            self.threshold = threshold
            self.floorValue = floorValue
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkTierView(_ item: NetworkTier) -> NetworkTierView {
        return NetworkTierView(
            code: item.code,
            titleText: item.title,
            payer: item.payer,
            capacity: String(item.capacity),
            weight: String(format: "%.2f", item.weight),
            budget: String(format: "%.2f", item.budget),
            endsAtText: String(item.endsAt),
            ratio: String(format: "%.2f", item.ratio),
            threshold: String(format: "%.2f", item.threshold),
            floorValue: String(format: "%.2f", item.floorValue),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkTierViews(_ items: [NetworkTier]) -> [NetworkTierView] {
        var views: [NetworkTierView] = []
        for item in items {
            views.append(toNetworkTierView(item))
        }
        return views
    }

    static func sumNetworkTierView(_ view: NetworkTierView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCapacity) + parsedWeight + parsedBudget
    }
}
