import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer metric.
    final class TransferMetricView {
        var codeText: String
        var nameText: String
        var locale: String
        var amountText: String
        var acuityText: String
        var ownerID: String
        var contactEmail: String
        var timezoneText: String
        var limitText: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, locale: String, amountText: String, acuityText: String, ownerID: String, contactEmail: String, timezoneText: String, limitText: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.locale = locale
            self.amountText = amountText
            self.acuityText = acuityText
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.timezoneText = timezoneText
            self.limitText = limitText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toTransferMetricView(_ item: TransferMetric) -> TransferMetricView {
        return TransferMetricView(
            codeText: item.code,
            nameText: item.name,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            amountText: String(format: "%.2f", item.amount),
            acuityText: String(item.acuity),
            ownerID: item.ownerID,
            contactEmail: item.contactEmail,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            limitText: String(item.limit),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferMetricViews(_ items: [TransferMetric]) -> [TransferMetricView] {
        var views: [TransferMetricView] = []
        for item in items {
            views.append(toTransferMetricView(item))
        }
        return views
    }

    static func sumTransferMetricView(_ view: TransferMetricView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedAmount + Double(parsedAcuity) + Double(parsedLimit)
    }
}
