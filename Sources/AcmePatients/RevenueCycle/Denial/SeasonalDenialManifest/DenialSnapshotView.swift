import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial snapshot.
    final class DenialSnapshotView {
        var codeText: String
        var nameText: String
        var budget: String
        var facility: String
        var acuity: String
        var discount: String
        var encounterIDText: String
        var description: String
        var attemptsText: String
        var currency: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, nameText: String, budget: String, facility: String, acuity: String, discount: String, encounterIDText: String, description: String, attemptsText: String, currency: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.budget = budget
            self.facility = facility
            self.acuity = acuity
            self.discount = discount
            self.encounterIDText = encounterIDText
            self.description = description
            self.attemptsText = attemptsText
            self.currency = currency
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toDenialSnapshotView(_ item: DenialSnapshot) -> DenialSnapshotView {
        return DenialSnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            budget: String(format: "%.2f", item.budget),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            acuity: String(item.acuity),
            discount: String(format: "%.2f", item.discount),
            encounterIDText: item.encounterID,
            description: item.description,
            attemptsText: String(item.attempts),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialSnapshotViews(_ items: [DenialSnapshot]) -> [DenialSnapshotView] {
        var views: [DenialSnapshotView] = []
        for item in items {
            views.append(toDenialSnapshotView(item))
        }
        return views
    }

    static func sumDenialSnapshotView(_ view: DenialSnapshotView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedBudget + Double(parsedAcuity) + parsedDiscount
    }
}
