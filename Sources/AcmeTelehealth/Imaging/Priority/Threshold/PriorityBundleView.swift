import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority bundle.
    final class PriorityBundleView {
        var codeText: String
        var title: String
        var amountText: String
        var visitMinutes: String
        var source: String
        var statusLabel: String

        init(codeText: String, title: String, amountText: String, visitMinutes: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.amountText = amountText
            self.visitMinutes = visitMinutes
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityBundleView(_ item: PriorityBundle) -> PriorityBundleView {
        return PriorityBundleView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            visitMinutes: String(item.visitMinutes),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityBundleViews(_ items: [PriorityBundle]) -> [PriorityBundleView] {
        var views: [PriorityBundleView] = []
        for item in items {
            views.append(toPriorityBundleView(item))
        }
        return views
    }

    static func sumPriorityBundleView(_ view: PriorityBundleView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedAmount + Double(parsedVisitMinutes)
    }
}
