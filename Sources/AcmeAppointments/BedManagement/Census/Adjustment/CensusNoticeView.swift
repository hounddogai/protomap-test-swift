import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census notice.
    final class CensusNoticeView {
        var code: String
        var titleText: String
        var capacityText: String
        var timezone: String
        var amount: String
        var payer: String
        var quantity: String
        var source: String
        var approvedText: String
        var durationMinutes: String
        var reviewer: String
        var statusLabel: String

        init(code: String, titleText: String, capacityText: String, timezone: String, amount: String, payer: String, quantity: String, source: String, approvedText: String, durationMinutes: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.capacityText = capacityText
            self.timezone = timezone
            self.amount = amount
            self.payer = payer
            self.quantity = quantity
            self.source = source
            self.approvedText = approvedText
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toCensusNoticeView(_ item: CensusNotice) -> CensusNoticeView {
        return CensusNoticeView(
            code: item.code,
            titleText: item.title,
            capacityText: String(item.capacity),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            amount: String(format: "%.2f", item.amount),
            payer: item.payer,
            quantity: String(item.quantity),
            source: Kit.Text.truncate(item.source, limit: 64),
            approvedText: "\(item.approved)",
            durationMinutes: String(item.durationMinutes),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusNoticeViews(_ items: [CensusNotice]) -> [CensusNoticeView] {
        var views: [CensusNoticeView] = []
        for item in items {
            views.append(toCensusNoticeView(item))
        }
        return views
    }

    static func sumCensusNoticeView(_ view: CensusNoticeView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedCapacity) + parsedAmount + Double(parsedQuantity)
    }
}
