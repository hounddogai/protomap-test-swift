import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program proposal.
    final class ProgramProposalView {
        var codeText: String
        var label: String
        var specialtyText: String
        var priority: String
        var segmentText: String
        var currencyText: String
        var maximum: String
        var archived: String
        var bed: String
        var statusLabel: String

        init(codeText: String, label: String, specialtyText: String, priority: String, segmentText: String, currencyText: String, maximum: String, archived: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.specialtyText = specialtyText
            self.priority = priority
            self.segmentText = segmentText
            self.currencyText = currencyText
            self.maximum = maximum
            self.archived = archived
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toProgramProposalView(_ item: ProgramProposal) -> ProgramProposalView {
        return ProgramProposalView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            specialtyText: item.specialty,
            priority: String(item.priority),
            segmentText: item.segment,
            currencyText: Kit.Text.truncate(item.currency, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            archived: "\(item.archived)",
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramProposalViews(_ items: [ProgramProposal]) -> [ProgramProposalView] {
        var views: [ProgramProposalView] = []
        for item in items {
            views.append(toProgramProposalView(item))
        }
        return views
    }

    static func sumProgramProposalView(_ view: ProgramProposalView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedPriority) + parsedMaximum
    }
}
