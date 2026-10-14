import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range summary.
    final class ReferenceRangeSummaryView {
        var code: String
        var label: String
        var acuity: String
        var budget: String
        var batchSize: String
        var clinicianID: String
        var ceiling: String
        var summaryText: String
        var margin: String
        var graceDaysText: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, label: String, acuity: String, budget: String, batchSize: String, clinicianID: String, ceiling: String, summaryText: String, margin: String, graceDaysText: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.budget = budget
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.summaryText = summaryText
            self.margin = margin
            self.graceDaysText = graceDaysText
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeSummaryView(_ item: ReferenceRangeSummary) -> ReferenceRangeSummaryView {
        return ReferenceRangeSummaryView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            acuity: String(item.acuity),
            budget: String(format: "%.2f", item.budget),
            batchSize: String(item.batchSize),
            clinicianID: item.clinicianID,
            ceiling: String(format: "%.2f", item.ceiling),
            summaryText: item.summary,
            margin: String(format: "%.2f", item.margin),
            graceDaysText: String(item.graceDays),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeSummaryViews(_ items: [ReferenceRangeSummary]) -> [ReferenceRangeSummaryView] {
        var views: [ReferenceRangeSummaryView] = []
        for item in items {
            views.append(toReferenceRangeSummaryView(item))
        }
        return views
    }

    static func sumReferenceRangeSummaryView(_ view: ReferenceRangeSummaryView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedAcuity) + parsedBudget + Double(parsedBatchSize)
    }
}
