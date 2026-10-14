import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy courier window.
    final class LegacyCourierWindowView {
        var code: String
        var title: String
        var amount: String
        var updatedAt: String
        var encounterIDText: String
        var category: String
        var batchSize: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, amount: String, updatedAt: String, encounterIDText: String, category: String, batchSize: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amount = amount
            self.updatedAt = updatedAt
            self.encounterIDText = encounterIDText
            self.category = category
            self.batchSize = batchSize
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCourierWindowView(_ item: LegacyCourierWindow) -> LegacyCourierWindowView {
        return LegacyCourierWindowView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            amount: String(format: "%.2f", item.amount),
            updatedAt: String(item.updatedAt),
            encounterIDText: item.encounterID,
            category: item.category,
            batchSize: String(item.batchSize),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCourierWindowViews(_ items: [LegacyCourierWindow]) -> [LegacyCourierWindowView] {
        var views: [LegacyCourierWindowView] = []
        for item in items {
            views.append(toLegacyCourierWindowView(item))
        }
        return views
    }

    static func sumLegacyCourierWindowView(_ view: LegacyCourierWindowView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedAmount + Double(parsedUpdatedAt) + Double(parsedBatchSize)
    }
}
