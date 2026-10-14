import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted charge policy.
    final class WeightedChargePolicyView {
        var codeText: String
        var label: String
        var contactEmailText: String
        var createdAtText: String
        var description: String
        var visitMinutes: String
        var nameText: String
        var region: String
        var statusLabel: String

        init(codeText: String, label: String, contactEmailText: String, createdAtText: String, description: String, visitMinutes: String, nameText: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.contactEmailText = contactEmailText
            self.createdAtText = createdAtText
            self.description = description
            self.visitMinutes = visitMinutes
            self.nameText = nameText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedChargePolicyView(_ item: WeightedChargePolicy) -> WeightedChargePolicyView {
        return WeightedChargePolicyView(
            codeText: item.code,
            label: item.label,
            contactEmailText: item.contactEmail,
            createdAtText: String(item.createdAt),
            description: item.description,
            visitMinutes: String(item.visitMinutes),
            nameText: Kit.Text.truncate(item.name, limit: 40),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedChargePolicyViews(_ items: [WeightedChargePolicy]) -> [WeightedChargePolicyView] {
        var views: [WeightedChargePolicyView] = []
        for item in items {
            views.append(toWeightedChargePolicyView(item))
        }
        return views
    }

    static func sumWeightedChargePolicyView(_ view: WeightedChargePolicyView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes)
    }
}
