import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global dispense summary.
    final class GlobalDispenseSummaryView {
        var codeText: String
        var titleText: String
        var quantity: String
        var locale: String
        var batchSizeText: String
        var statusLabel: String

        init(codeText: String, titleText: String, quantity: String, locale: String, batchSizeText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.quantity = quantity
            self.locale = locale
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDispenseSummaryView(_ item: GlobalDispenseSummary) -> GlobalDispenseSummaryView {
        return GlobalDispenseSummaryView(
            codeText: item.code,
            titleText: item.title,
            quantity: String(item.quantity),
            locale: item.locale,
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDispenseSummaryViews(_ items: [GlobalDispenseSummary]) -> [GlobalDispenseSummaryView] {
        var views: [GlobalDispenseSummaryView] = []
        for item in items {
            views.append(toGlobalDispenseSummaryView(item))
        }
        return views
    }

    static func sumGlobalDispenseSummaryView(_ view: GlobalDispenseSummaryView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedQuantity) + Double(parsedBatchSize)
    }
}
