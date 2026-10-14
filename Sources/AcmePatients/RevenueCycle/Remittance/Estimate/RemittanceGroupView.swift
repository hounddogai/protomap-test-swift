import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance group.
    final class RemittanceGroupView {
        var codeText: String
        var nameText: String
        var ceilingText: String
        var capacityText: String
        var minimum: String
        var archived: String
        var amount: String
        var payer: String
        var durationMinutesText: String
        var statusLabel: String

        init(codeText: String, nameText: String, ceilingText: String, capacityText: String, minimum: String, archived: String, amount: String, payer: String, durationMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ceilingText = ceilingText
            self.capacityText = capacityText
            self.minimum = minimum
            self.archived = archived
            self.amount = amount
            self.payer = payer
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceGroupView(_ item: RemittanceGroup) -> RemittanceGroupView {
        return RemittanceGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            capacityText: String(item.capacity),
            minimum: String(format: "%.2f", item.minimum),
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            payer: item.payer,
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceGroupViews(_ items: [RemittanceGroup]) -> [RemittanceGroupView] {
        var views: [RemittanceGroupView] = []
        for item in items {
            views.append(toRemittanceGroupView(item))
        }
        return views
    }

    static func sumRemittanceGroupView(_ view: RemittanceGroupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedCeiling + Double(parsedCapacity) + parsedMinimum
    }
}
