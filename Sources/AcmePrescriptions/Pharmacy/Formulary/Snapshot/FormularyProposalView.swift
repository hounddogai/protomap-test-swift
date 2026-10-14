import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary proposal.
    final class FormularyProposalView {
        var codeText: String
        var name: String
        var minimumText: String
        var description: String
        var durationMinutes: String
        var floorValue: String
        var segment: String
        var title: String
        var statusLabel: String

        init(codeText: String, name: String, minimumText: String, description: String, durationMinutes: String, floorValue: String, segment: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.minimumText = minimumText
            self.description = description
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
            self.segment = segment
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyProposalView(_ item: FormularyProposal) -> FormularyProposalView {
        return FormularyProposalView(
            codeText: item.code,
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            description: item.description,
            durationMinutes: String(item.durationMinutes),
            floorValue: String(format: "%.2f", item.floorValue),
            segment: item.segment,
            title: Kit.Text.truncate(item.title, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyProposalViews(_ items: [FormularyProposal]) -> [FormularyProposalView] {
        var views: [FormularyProposalView] = []
        for item in items {
            views.append(toFormularyProposalView(item))
        }
        return views
    }

    static func sumFormularyProposalView(_ view: FormularyProposalView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMinimum + Double(parsedDurationMinutes) + parsedFloorValue
    }
}
