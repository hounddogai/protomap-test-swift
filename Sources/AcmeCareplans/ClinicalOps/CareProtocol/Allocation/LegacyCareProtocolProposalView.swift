import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy care protocol proposal.
    final class LegacyCareProtocolProposalView {
        var codeText: String
        var name: String
        var visitMinutesText: String
        var notes: String
        var patientRefText: String
        var timezoneText: String
        var startsAt: String
        var procedureCode: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, name: String, visitMinutesText: String, notes: String, patientRefText: String, timezoneText: String, startsAt: String, procedureCode: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visitMinutesText = visitMinutesText
            self.notes = notes
            self.patientRefText = patientRefText
            self.timezoneText = timezoneText
            self.startsAt = startsAt
            self.procedureCode = procedureCode
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCareProtocolProposalView(_ item: LegacyCareProtocolProposal) -> LegacyCareProtocolProposalView {
        return LegacyCareProtocolProposalView(
            codeText: item.code,
            name: item.name,
            visitMinutesText: String(item.visitMinutes),
            notes: item.notes,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            startsAt: String(item.startsAt),
            procedureCode: item.procedureCode,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCareProtocolProposalViews(_ items: [LegacyCareProtocolProposal]) -> [LegacyCareProtocolProposalView] {
        var views: [LegacyCareProtocolProposalView] = []
        for item in items {
            views.append(toLegacyCareProtocolProposalView(item))
        }
        return views
    }

    static func sumLegacyCareProtocolProposalView(_ view: LegacyCareProtocolProposalView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedStartsAt) + Double(parsedCapacity)
    }
}
