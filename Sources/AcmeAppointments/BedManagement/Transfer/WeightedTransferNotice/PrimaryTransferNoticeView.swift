import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary transfer notice.
    final class PrimaryTransferNoticeView {
        var code: String
        var title: String
        var description: String
        var allergy: String
        var amountText: String
        var statusLabel: String

        init(code: String, title: String, description: String, allergy: String, amountText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.allergy = allergy
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryTransferNoticeView(_ item: PrimaryTransferNotice) -> PrimaryTransferNoticeView {
        return PrimaryTransferNoticeView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            description: Kit.Text.truncate(item.description, limit: 64),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryTransferNoticeViews(_ items: [PrimaryTransferNotice]) -> [PrimaryTransferNoticeView] {
        var views: [PrimaryTransferNoticeView] = []
        for item in items {
            views.append(toPrimaryTransferNoticeView(item))
        }
        return views
    }

    static func sumPrimaryTransferNoticeView(_ view: PrimaryTransferNoticeView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
