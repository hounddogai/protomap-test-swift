import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped census baseline.
    final class CappedCensusBaselineView {
        var code: String
        var titleText: String
        var region: String
        var ratio: String
        var unit: String
        var copay: String
        var refills: String
        var attemptsText: String
        var quantity: String
        var summaryText: String
        var statusLabel: String

        init(code: String, titleText: String, region: String, ratio: String, unit: String, copay: String, refills: String, attemptsText: String, quantity: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.region = region
            self.ratio = ratio
            self.unit = unit
            self.copay = copay
            self.refills = refills
            self.attemptsText = attemptsText
            self.quantity = quantity
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCensusBaselineView(_ item: CappedCensusBaseline) -> CappedCensusBaselineView {
        return CappedCensusBaselineView(
            code: item.code,
            titleText: item.title,
            region: item.region,
            ratio: String(format: "%.2f", item.ratio),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            copay: String(format: "%.2f", item.copay),
            refills: String(item.refills),
            attemptsText: String(item.attempts),
            quantity: String(item.quantity),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCensusBaselineViews(_ items: [CappedCensusBaseline]) -> [CappedCensusBaselineView] {
        var views: [CappedCensusBaselineView] = []
        for item in items {
            views.append(toCappedCensusBaselineView(item))
        }
        return views
    }

    static func sumCappedCensusBaselineView(_ view: CappedCensusBaselineView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRatio + parsedCopay + Double(parsedRefills)
    }
}
