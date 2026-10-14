import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled witness proposal.
    final class ScheduledWitnessProposalView {
        var code: String
        var name: String
        var procedureCodeText: String
        var source: String
        var unit: String
        var marginText: String
        var externalRef: String
        var durationMinutesText: String
        var priority: String
        var acuity: String
        var approvedText: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, source: String, unit: String, marginText: String, externalRef: String, durationMinutesText: String, priority: String, acuity: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.source = source
            self.unit = unit
            self.marginText = marginText
            self.externalRef = externalRef
            self.durationMinutesText = durationMinutesText
            self.priority = priority
            self.acuity = acuity
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledWitnessProposalView(_ item: ScheduledWitnessProposal) -> ScheduledWitnessProposalView {
        return ScheduledWitnessProposalView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 40),
            procedureCodeText: item.procedureCode,
            source: item.source,
            unit: item.unit,
            marginText: String(format: "%.2f", item.margin),
            externalRef: item.externalRef,
            durationMinutesText: String(item.durationMinutes),
            priority: String(item.priority),
            acuity: String(item.acuity),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledWitnessProposalViews(_ items: [ScheduledWitnessProposal]) -> [ScheduledWitnessProposalView] {
        var views: [ScheduledWitnessProposalView] = []
        for item in items {
            views.append(toScheduledWitnessProposalView(item))
        }
        return views
    }

    static func sumScheduledWitnessProposalView(_ view: ScheduledWitnessProposalView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMargin + Double(parsedDurationMinutes) + Double(parsedPriority)
    }
}
