import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary study baseline.
    final class PrimaryStudyBaselineView {
        var code: String
        var label: String
        var maximumText: String
        var region: String
        var payer: String
        var ceiling: String
        var statusLabel: String

        init(code: String, label: String, maximumText: String, region: String, payer: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximumText = maximumText
            self.region = region
            self.payer = payer
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryStudyBaselineView(_ item: PrimaryStudyBaseline) -> PrimaryStudyBaselineView {
        return PrimaryStudyBaselineView(
            code: item.code,
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            region: item.region,
            payer: Kit.Text.truncate(item.payer, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryStudyBaselineViews(_ items: [PrimaryStudyBaseline]) -> [PrimaryStudyBaselineView] {
        var views: [PrimaryStudyBaselineView] = []
        for item in items {
            views.append(toPrimaryStudyBaselineView(item))
        }
        return views
    }

    static func sumPrimaryStudyBaselineView(_ view: PrimaryStudyBaselineView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedMaximum + parsedCeiling
    }
}
