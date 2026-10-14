import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending statement proposal.
    final class PendingStatementProposalView {
        var code: String
        var name: String
        var currency: String
        var allergy: String
        var active: String
        var ownerID: String
        var visitMinutesText: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, name: String, currency: String, allergy: String, active: String, ownerID: String, visitMinutesText: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currency = currency
            self.allergy = allergy
            self.active = active
            self.ownerID = ownerID
            self.visitMinutesText = visitMinutesText
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingStatementProposalView(_ item: PendingStatementProposal) -> PendingStatementProposalView {
        return PendingStatementProposalView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            currency: item.currency,
            allergy: item.allergy,
            active: "\(item.active)",
            ownerID: item.ownerID,
            visitMinutesText: String(item.visitMinutes),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingStatementProposalViews(_ items: [PendingStatementProposal]) -> [PendingStatementProposalView] {
        var views: [PendingStatementProposalView] = []
        for item in items {
            views.append(toPendingStatementProposalView(item))
        }
        return views
    }

    static func sumPendingStatementProposalView(_ view: PendingStatementProposalView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
