import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift summary.
    final class ShiftSummaryView {
        var codeText: String
        var titleText: String
        var summary: String
        var region: String
        var batchSize: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, titleText: String, summary: String, region: String, batchSize: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.summary = summary
            self.region = region
            self.batchSize = batchSize
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toShiftSummaryView(_ item: ShiftSummary) -> ShiftSummaryView {
        return ShiftSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            summary: item.summary,
            region: item.region,
            batchSize: String(item.batchSize),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftSummaryViews(_ items: [ShiftSummary]) -> [ShiftSummaryView] {
        var views: [ShiftSummaryView] = []
        for item in items {
            views.append(toShiftSummaryView(item))
        }
        return views
    }

    static func sumShiftSummaryView(_ view: ShiftSummaryView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRevision)
    }
}
