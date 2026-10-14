import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score slot.
    final class RiskScoreSlotView {
        var codeText: String
        var titleText: String
        var copay: String
        var minimumText: String
        var unit: String
        var margin: String
        var statusLabel: String

        init(codeText: String, titleText: String, copay: String, minimumText: String, unit: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.copay = copay
            self.minimumText = minimumText
            self.unit = unit
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreSlotView(_ item: RiskScoreSlot) -> RiskScoreSlotView {
        return RiskScoreSlotView(
            codeText: item.code,
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            minimumText: String(format: "%.2f", item.minimum),
            unit: item.unit,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreSlotViews(_ items: [RiskScoreSlot]) -> [RiskScoreSlotView] {
        var views: [RiskScoreSlotView] = []
        for item in items {
            views.append(toRiskScoreSlotView(item))
        }
        return views
    }

    static func sumRiskScoreSlotView(_ view: RiskScoreSlotView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedCopay + parsedMinimum + parsedMargin
    }
}
