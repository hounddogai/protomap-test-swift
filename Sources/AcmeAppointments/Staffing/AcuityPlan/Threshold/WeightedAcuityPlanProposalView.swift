import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted acuity plan proposal.
    final class WeightedAcuityPlanProposalView {
        var code: String
        var label: String
        var unit: String
        var floorValue: String
        var sequenceText: String
        var cost: String
        var title: String
        var payerText: String
        var region: String
        var procedureCode: String
        var active: String
        var statusLabel: String

        init(code: String, label: String, unit: String, floorValue: String, sequenceText: String, cost: String, title: String, payerText: String, region: String, procedureCode: String, active: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unit = unit
            self.floorValue = floorValue
            self.sequenceText = sequenceText
            self.cost = cost
            self.title = title
            self.payerText = payerText
            self.region = region
            self.procedureCode = procedureCode
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAcuityPlanProposalView(_ item: WeightedAcuityPlanProposal) -> WeightedAcuityPlanProposalView {
        return WeightedAcuityPlanProposalView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            unit: item.unit,
            floorValue: String(format: "%.2f", item.floorValue),
            sequenceText: String(item.sequence),
            cost: String(format: "%.2f", item.cost),
            title: item.title,
            payerText: item.payer,
            region: item.region,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAcuityPlanProposalViews(_ items: [WeightedAcuityPlanProposal]) -> [WeightedAcuityPlanProposalView] {
        var views: [WeightedAcuityPlanProposalView] = []
        for item in items {
            views.append(toWeightedAcuityPlanProposalView(item))
        }
        return views
    }

    static func sumWeightedAcuityPlanProposalView(_ view: WeightedAcuityPlanProposalView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedFloorValue + Double(parsedSequence) + parsedCost
    }
}
