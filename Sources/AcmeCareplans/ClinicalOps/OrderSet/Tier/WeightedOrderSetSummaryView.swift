import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted order set summary.
    final class WeightedOrderSetSummaryView {
        var code: String
        var labelText: String
        var archivedText: String
        var visibleText: String
        var segment: String
        var limitText: String
        var versionText: String
        var source: String
        var statusLabel: String

        init(code: String, labelText: String, archivedText: String, visibleText: String, segment: String, limitText: String, versionText: String, source: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archivedText = archivedText
            self.visibleText = visibleText
            self.segment = segment
            self.limitText = limitText
            self.versionText = versionText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOrderSetSummaryView(_ item: WeightedOrderSetSummary) -> WeightedOrderSetSummaryView {
        return WeightedOrderSetSummaryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            archivedText: "\(item.archived)",
            visibleText: "\(item.visible)",
            segment: item.segment,
            limitText: String(item.limit),
            versionText: String(item.version),
            source: Kit.Text.truncate(item.source, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOrderSetSummaryViews(_ items: [WeightedOrderSetSummary]) -> [WeightedOrderSetSummaryView] {
        var views: [WeightedOrderSetSummaryView] = []
        for item in items {
            views.append(toWeightedOrderSetSummaryView(item))
        }
        return views
    }

    static func sumWeightedOrderSetSummaryView(_ view: WeightedOrderSetSummaryView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedLimit) + Double(parsedVersion)
    }
}
