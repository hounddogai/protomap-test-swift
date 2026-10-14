import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual formulary rollup.
    final class ManualFormularyRollupView {
        var code: String
        var name: String
        var discount: String
        var facility: String
        var batchSizeText: String
        var updatedAt: String
        var retriesText: String
        var costText: String
        var statusLabel: String

        init(code: String, name: String, discount: String, facility: String, batchSizeText: String, updatedAt: String, retriesText: String, costText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discount = discount
            self.facility = facility
            self.batchSizeText = batchSizeText
            self.updatedAt = updatedAt
            self.retriesText = retriesText
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toManualFormularyRollupView(_ item: ManualFormularyRollup) -> ManualFormularyRollupView {
        return ManualFormularyRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            facility: item.facility,
            batchSizeText: String(item.batchSize),
            updatedAt: String(item.updatedAt),
            retriesText: String(item.retries),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFormularyRollupViews(_ items: [ManualFormularyRollup]) -> [ManualFormularyRollupView] {
        var views: [ManualFormularyRollupView] = []
        for item in items {
            views.append(toManualFormularyRollupView(item))
        }
        return views
    }

    static func sumManualFormularyRollupView(_ view: ManualFormularyRollupView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedDiscount + Double(parsedBatchSize) + Double(parsedUpdatedAt)
    }
}
