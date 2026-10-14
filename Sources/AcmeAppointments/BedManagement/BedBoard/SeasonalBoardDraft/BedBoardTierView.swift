import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board tier.
    final class BedBoardTierView {
        var code: String
        var title: String
        var quantity: String
        var label: String
        var phone: String
        var batchSize: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, label: String, phone: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.label = label
            self.phone = phone
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardTierView(_ item: BedBoardTier) -> BedBoardTierView {
        return BedBoardTierView(
            code: item.code,
            title: item.title,
            quantity: String(item.quantity),
            label: item.label,
            phone: Kit.Text.truncate(item.phone, limit: 80),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardTierViews(_ items: [BedBoardTier]) -> [BedBoardTierView] {
        var views: [BedBoardTierView] = []
        for item in items {
            views.append(toBedBoardTierView(item))
        }
        return views
    }

    static func sumBedBoardTierView(_ view: BedBoardTierView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedQuantity) + Double(parsedBatchSize)
    }
}
