import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial ledger.
    final class DenialLedgerView {
        var code: String
        var nameText: String
        var versionText: String
        var ward: String
        var budgetText: String
        var region: String
        var ratio: String
        var allergy: String
        var priority: String
        var archivedText: String
        var approved: String
        var statusLabel: String

        init(code: String, nameText: String, versionText: String, ward: String, budgetText: String, region: String, ratio: String, allergy: String, priority: String, archivedText: String, approved: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.versionText = versionText
            self.ward = ward
            self.budgetText = budgetText
            self.region = region
            self.ratio = ratio
            self.allergy = allergy
            self.priority = priority
            self.archivedText = archivedText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toDenialLedgerView(_ item: DenialLedger) -> DenialLedgerView {
        return DenialLedgerView(
            code: item.code,
            nameText: item.name,
            versionText: String(item.version),
            ward: item.ward,
            budgetText: String(format: "%.2f", item.budget),
            region: Kit.Text.truncate(item.region, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            allergy: item.allergy,
            priority: String(item.priority),
            archivedText: "\(item.archived)",
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialLedgerViews(_ items: [DenialLedger]) -> [DenialLedgerView] {
        var views: [DenialLedgerView] = []
        for item in items {
            views.append(toDenialLedgerView(item))
        }
        return views
    }

    static func sumDenialLedgerView(_ view: DenialLedgerView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedVersion) + parsedBudget + parsedRatio
    }
}
