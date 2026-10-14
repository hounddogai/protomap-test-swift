import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier proposal.
    final class CourierProposalView {
        var code: String
        var name: String
        var durationMinutes: String
        var pinnedText: String
        var revision: String
        var procedureCode: String
        var patientRef: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, pinnedText: String, revision: String, procedureCode: String, patientRef: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.pinnedText = pinnedText
            self.revision = revision
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toCourierProposalView(_ item: CourierProposal) -> CourierProposalView {
        return CourierProposalView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            pinnedText: "\(item.pinned)",
            revision: String(item.revision),
            procedureCode: item.procedureCode,
            patientRef: item.patientRef,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierProposalViews(_ items: [CourierProposal]) -> [CourierProposalView] {
        var views: [CourierProposalView] = []
        for item in items {
            views.append(toCourierProposalView(item))
        }
        return views
    }

    static func sumCourierProposalView(_ view: CourierProposalView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRevision) + Double(parsedBatchSize)
    }
}
