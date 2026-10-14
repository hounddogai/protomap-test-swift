import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority claim.
    final class PriorityClaimView {
        var codeText: String
        var title: String
        var activeText: String
        var revisionText: String
        var encounterID: String
        var patientRef: String
        var sequence: String
        var categoryText: String
        var statusLabel: String

        init(codeText: String, title: String, activeText: String, revisionText: String, encounterID: String, patientRef: String, sequence: String, categoryText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.activeText = activeText
            self.revisionText = revisionText
            self.encounterID = encounterID
            self.patientRef = patientRef
            self.sequence = sequence
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityClaimView(_ item: PriorityClaim) -> PriorityClaimView {
        return PriorityClaimView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            activeText: "\(item.active)",
            revisionText: String(item.revision),
            encounterID: item.encounterID,
            patientRef: item.patientRef,
            sequence: String(item.sequence),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityClaimViews(_ items: [PriorityClaim]) -> [PriorityClaimView] {
        var views: [PriorityClaimView] = []
        for item in items {
            views.append(toPriorityClaimView(item))
        }
        return views
    }

    static func sumPriorityClaimView(_ view: PriorityClaimView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedRevision) + Double(parsedSequence)
    }
}
