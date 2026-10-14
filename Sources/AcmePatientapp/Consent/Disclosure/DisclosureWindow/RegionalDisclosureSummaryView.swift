import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional disclosure summary.
    final class RegionalDisclosureSummaryView {
        var codeText: String
        var labelText: String
        var minimum: String
        var batchSize: String
        var country: String
        var statusLabel: String

        init(codeText: String, labelText: String, minimum: String, batchSize: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.minimum = minimum
            self.batchSize = batchSize
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDisclosureSummaryView(_ item: RegionalDisclosureSummary) -> RegionalDisclosureSummaryView {
        return RegionalDisclosureSummaryView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            batchSize: String(item.batchSize),
            country: Kit.Text.truncate(item.country, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDisclosureSummaryViews(_ items: [RegionalDisclosureSummary]) -> [RegionalDisclosureSummaryView] {
        var views: [RegionalDisclosureSummaryView] = []
        for item in items {
            views.append(toRegionalDisclosureSummaryView(item))
        }
        return views
    }

    static func sumRegionalDisclosureSummaryView(_ view: RegionalDisclosureSummaryView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMinimum + Double(parsedBatchSize)
    }
}
