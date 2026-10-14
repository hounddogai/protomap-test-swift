import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist summary.
    final class WorklistSummaryView {
        var code: String
        var titleText: String
        var active: String
        var sequence: String
        var payer: String
        var description: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, titleText: String, active: String, sequence: String, payer: String, description: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.active = active
            self.sequence = sequence
            self.payer = payer
            self.description = description
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistSummaryView(_ item: WorklistSummary) -> WorklistSummaryView {
        return WorklistSummaryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            active: "\(item.active)",
            sequence: String(item.sequence),
            payer: item.payer,
            description: item.description,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistSummaryViews(_ items: [WorklistSummary]) -> [WorklistSummaryView] {
        var views: [WorklistSummaryView] = []
        for item in items {
            views.append(toWorklistSummaryView(item))
        }
        return views
    }

    static func sumWorklistSummaryView(_ view: WorklistSummaryView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedSequence) + Double(parsedExpiresAt)
    }
}
