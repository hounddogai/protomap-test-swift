import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel baseline.
    final class PanelBaselineView {
        var code: String
        var title: String
        var updatedAtText: String
        var categoryText: String
        var bedText: String
        var procedureCodeText: String
        var region: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, updatedAtText: String, categoryText: String, bedText: String, procedureCodeText: String, region: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAtText = updatedAtText
            self.categoryText = categoryText
            self.bedText = bedText
            self.procedureCodeText = procedureCodeText
            self.region = region
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toPanelBaselineView(_ item: PanelBaseline) -> PanelBaselineView {
        return PanelBaselineView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 80),
            updatedAtText: String(item.updatedAt),
            categoryText: item.category,
            bedText: item.bed,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            region: item.region,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelBaselineViews(_ items: [PanelBaseline]) -> [PanelBaselineView] {
        var views: [PanelBaselineView] = []
        for item in items {
            views.append(toPanelBaselineView(item))
        }
        return views
    }

    static func sumPanelBaselineView(_ view: PanelBaselineView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedUpdatedAt) + parsedAmount
    }
}
