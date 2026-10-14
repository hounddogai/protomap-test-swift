import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan variance.
    final class DischargePlanVarianceView {
        var code: String
        var name: String
        var capacityText: String
        var retriesText: String
        var cost: String
        var rate: String
        var ownerID: String
        var contactEmail: String
        var discount: String
        var statusLabel: String

        init(code: String, name: String, capacityText: String, retriesText: String, cost: String, rate: String, ownerID: String, contactEmail: String, discount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacityText = capacityText
            self.retriesText = retriesText
            self.cost = cost
            self.rate = rate
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanVarianceView(_ item: DischargePlanVariance) -> DischargePlanVarianceView {
        return DischargePlanVarianceView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            capacityText: String(item.capacity),
            retriesText: String(item.retries),
            cost: String(format: "%.2f", item.cost),
            rate: String(format: "%.2f", item.rate),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            contactEmail: item.contactEmail,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanVarianceViews(_ items: [DischargePlanVariance]) -> [DischargePlanVarianceView] {
        var views: [DischargePlanVarianceView] = []
        for item in items {
            views.append(toDischargePlanVarianceView(item))
        }
        return views
    }

    static func sumDischargePlanVarianceView(_ view: DischargePlanVarianceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRetries) + parsedCost
    }
}
