import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol snapshot.
    final class CareProtocolSnapshotView {
        var codeText: String
        var name: String
        var startsAtText: String
        var encounterID: String
        var timezone: String
        var budgetText: String
        var currency: String
        var statusLabel: String

        init(codeText: String, name: String, startsAtText: String, encounterID: String, timezone: String, budgetText: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.startsAtText = startsAtText
            self.encounterID = encounterID
            self.timezone = timezone
            self.budgetText = budgetText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolSnapshotView(_ item: CareProtocolSnapshot) -> CareProtocolSnapshotView {
        return CareProtocolSnapshotView(
            codeText: item.code,
            name: item.name,
            startsAtText: String(item.startsAt),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            timezone: item.timezone,
            budgetText: String(format: "%.2f", item.budget),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolSnapshotViews(_ items: [CareProtocolSnapshot]) -> [CareProtocolSnapshotView] {
        var views: [CareProtocolSnapshotView] = []
        for item in items {
            views.append(toCareProtocolSnapshotView(item))
        }
        return views
    }

    static func sumCareProtocolSnapshotView(_ view: CareProtocolSnapshotView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedStartsAt) + parsedBudget
    }
}
