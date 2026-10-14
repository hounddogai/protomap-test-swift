import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled overtime proposal.
    final class ScheduledOvertimeProposalView {
        var code: String
        var label: String
        var name: String
        var procedureCodeText: String
        var payerText: String
        var segment: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, name: String, procedureCodeText: String, payerText: String, segment: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.payerText = payerText
            self.segment = segment
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledOvertimeProposalView(_ item: ScheduledOvertimeProposal) -> ScheduledOvertimeProposalView {
        return ScheduledOvertimeProposalView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            procedureCodeText: item.procedureCode,
            payerText: item.payer,
            segment: Kit.Text.truncate(item.segment, limit: 120),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledOvertimeProposalViews(_ items: [ScheduledOvertimeProposal]) -> [ScheduledOvertimeProposalView] {
        var views: [ScheduledOvertimeProposalView] = []
        for item in items {
            views.append(toScheduledOvertimeProposalView(item))
        }
        return views
    }

    static func sumScheduledOvertimeProposalView(_ view: ScheduledOvertimeProposalView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
