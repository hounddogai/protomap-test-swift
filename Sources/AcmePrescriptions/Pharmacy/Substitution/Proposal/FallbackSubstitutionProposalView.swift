import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback substitution proposal.
    final class FallbackSubstitutionProposalView {
        var codeText: String
        var label: String
        var approved: String
        var procedureCode: String
        var minimum: String
        var margin: String
        var windowDays: String
        var clinicianID: String
        var segment: String
        var statusLabel: String

        init(codeText: String, label: String, approved: String, procedureCode: String, minimum: String, margin: String, windowDays: String, clinicianID: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.approved = approved
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.margin = margin
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSubstitutionProposalView(_ item: FallbackSubstitutionProposal) -> FallbackSubstitutionProposalView {
        return FallbackSubstitutionProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            approved: "\(item.approved)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            margin: String(format: "%.2f", item.margin),
            windowDays: String(item.windowDays),
            clinicianID: item.clinicianID,
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSubstitutionProposalViews(_ items: [FallbackSubstitutionProposal]) -> [FallbackSubstitutionProposalView] {
        var views: [FallbackSubstitutionProposalView] = []
        for item in items {
            views.append(toFallbackSubstitutionProposalView(item))
        }
        return views
    }

    static func sumFallbackSubstitutionProposalView(_ view: FallbackSubstitutionProposalView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedMinimum + parsedMargin + Double(parsedWindowDays)
    }
}
