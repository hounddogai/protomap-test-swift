import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy accession proposal.
    final class LegacyAccessionProposalView {
        var code: String
        var nameText: String
        var floorValue: String
        var cost: String
        var label: String
        var dosageMgText: String
        var windowDaysText: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, floorValue: String, cost: String, label: String, dosageMgText: String, windowDaysText: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.floorValue = floorValue
            self.cost = cost
            self.label = label
            self.dosageMgText = dosageMgText
            self.windowDaysText = windowDaysText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAccessionProposalView(_ item: LegacyAccessionProposal) -> LegacyAccessionProposalView {
        return LegacyAccessionProposalView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            cost: String(format: "%.2f", item.cost),
            label: Kit.Text.truncate(item.label, limit: 120),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            windowDaysText: String(item.windowDays),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAccessionProposalViews(_ items: [LegacyAccessionProposal]) -> [LegacyAccessionProposalView] {
        var views: [LegacyAccessionProposalView] = []
        for item in items {
            views.append(toLegacyAccessionProposalView(item))
        }
        return views
    }

    static func sumLegacyAccessionProposalView(_ view: LegacyAccessionProposalView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedFloorValue + parsedCost + parsedDosageMg
    }
}
