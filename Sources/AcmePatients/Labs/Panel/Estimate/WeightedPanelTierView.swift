import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted panel tier.
    final class WeightedPanelTierView {
        var code: String
        var label: String
        var bed: String
        var visitMinutesText: String
        var sequenceText: String
        var regionText: String
        var statusLabel: String

        init(code: String, label: String, bed: String, visitMinutesText: String, sequenceText: String, regionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bed = bed
            self.visitMinutesText = visitMinutesText
            self.sequenceText = sequenceText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedPanelTierView(_ item: WeightedPanelTier) -> WeightedPanelTierView {
        return WeightedPanelTierView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            bed: item.bed,
            visitMinutesText: String(item.visitMinutes),
            sequenceText: String(item.sequence),
            regionText: Kit.Text.truncate(item.region, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedPanelTierViews(_ items: [WeightedPanelTier]) -> [WeightedPanelTierView] {
        var views: [WeightedPanelTierView] = []
        for item in items {
            views.append(toWeightedPanelTierView(item))
        }
        return views
    }

    static func sumWeightedPanelTierView(_ view: WeightedPanelTierView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedSequence)
    }
}
