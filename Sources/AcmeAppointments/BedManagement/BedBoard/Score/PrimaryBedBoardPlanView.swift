import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary bed board plan.
    final class PrimaryBedBoardPlanView {
        var code: String
        var name: String
        var scoreText: String
        var unitText: String
        var approvedText: String
        var phone: String
        var sequence: String
        var refills: String
        var currencyText: String
        var statusLabel: String

        init(code: String, name: String, scoreText: String, unitText: String, approvedText: String, phone: String, sequence: String, refills: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.scoreText = scoreText
            self.unitText = unitText
            self.approvedText = approvedText
            self.phone = phone
            self.sequence = sequence
            self.refills = refills
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryBedBoardPlanView(_ item: PrimaryBedBoardPlan) -> PrimaryBedBoardPlanView {
        return PrimaryBedBoardPlanView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            scoreText: String(format: "%.2f", item.score),
            unitText: Kit.Text.truncate(item.unit, limit: 64),
            approvedText: "\(item.approved)",
            phone: Kit.Text.truncate(item.phone, limit: 64),
            sequence: String(item.sequence),
            refills: String(item.refills),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryBedBoardPlanViews(_ items: [PrimaryBedBoardPlan]) -> [PrimaryBedBoardPlanView] {
        var views: [PrimaryBedBoardPlanView] = []
        for item in items {
            views.append(toPrimaryBedBoardPlanView(item))
        }
        return views
    }

    static func sumPrimaryBedBoardPlanView(_ view: PrimaryBedBoardPlanView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedScore + Double(parsedSequence) + Double(parsedRefills)
    }
}
