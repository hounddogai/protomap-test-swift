import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped panel budget.
    final class CappedPanelBudgetView {
        var code: String
        var titleText: String
        var limitText: String
        var labelText: String
        var externalRefText: String
        var reviewer: String
        var payer: String
        var facilityText: String
        var source: String
        var bed: String
        var statusLabel: String

        init(code: String, titleText: String, limitText: String, labelText: String, externalRefText: String, reviewer: String, payer: String, facilityText: String, source: String, bed: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.limitText = limitText
            self.labelText = labelText
            self.externalRefText = externalRefText
            self.reviewer = reviewer
            self.payer = payer
            self.facilityText = facilityText
            self.source = source
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toCappedPanelBudgetView(_ item: CappedPanelBudget) -> CappedPanelBudgetView {
        return CappedPanelBudgetView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            limitText: String(item.limit),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            externalRefText: item.externalRef,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            payer: item.payer,
            facilityText: Kit.Text.truncate(item.facility, limit: 80),
            source: item.source,
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedPanelBudgetViews(_ items: [CappedPanelBudget]) -> [CappedPanelBudgetView] {
        var views: [CappedPanelBudgetView] = []
        for item in items {
            views.append(toCappedPanelBudgetView(item))
        }
        return views
    }

    static func sumCappedPanelBudgetView(_ view: CappedPanelBudgetView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
