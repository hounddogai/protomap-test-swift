import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient overtime proposal.
    final class LenientOvertimeProposalView {
        var codeText: String
        var labelText: String
        var acuityText: String
        var attempts: String
        var priority: String
        var statusLabel: String

        init(codeText: String, labelText: String, acuityText: String, attempts: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.acuityText = acuityText
            self.attempts = attempts
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOvertimeProposalView(_ item: LenientOvertimeProposal) -> LenientOvertimeProposalView {
        return LenientOvertimeProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            acuityText: String(item.acuity),
            attempts: String(item.attempts),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOvertimeProposalViews(_ items: [LenientOvertimeProposal]) -> [LenientOvertimeProposalView] {
        var views: [LenientOvertimeProposalView] = []
        for item in items {
            views.append(toLenientOvertimeProposalView(item))
        }
        return views
    }

    static func sumLenientOvertimeProposalView(_ view: LenientOvertimeProposalView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedAcuity) + Double(parsedAttempts) + Double(parsedPriority)
    }
}
