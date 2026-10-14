import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional recall proposal.
    final class RegionalRecallProposalView {
        var codeText: String
        var name: String
        var cost: String
        var encounterIDText: String
        var copay: String
        var procedureCode: String
        var durationMinutesText: String
        var payer: String
        var reviewerText: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, name: String, cost: String, encounterIDText: String, copay: String, procedureCode: String, durationMinutesText: String, payer: String, reviewerText: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.cost = cost
            self.encounterIDText = encounterIDText
            self.copay = copay
            self.procedureCode = procedureCode
            self.durationMinutesText = durationMinutesText
            self.payer = payer
            self.reviewerText = reviewerText
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRecallProposalView(_ item: RegionalRecallProposal) -> RegionalRecallProposalView {
        return RegionalRecallProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 80),
            copay: String(format: "%.2f", item.copay),
            procedureCode: item.procedureCode,
            durationMinutesText: String(item.durationMinutes),
            payer: item.payer,
            reviewerText: item.reviewer,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRecallProposalViews(_ items: [RegionalRecallProposal]) -> [RegionalRecallProposalView] {
        var views: [RegionalRecallProposalView] = []
        for item in items {
            views.append(toRegionalRecallProposalView(item))
        }
        return views
    }

    static func sumRegionalRecallProposalView(_ view: RegionalRecallProposalView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCost + parsedCopay + Double(parsedDurationMinutes)
    }
}
