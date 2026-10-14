import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary remittance request.
    final class PrimaryRemittanceRequestView {
        var codeText: String
        var title: String
        var windowDays: String
        var currency: String
        var batchSize: String
        var amount: String
        var statusLabel: String

        init(codeText: String, title: String, windowDays: String, currency: String, batchSize: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.windowDays = windowDays
            self.currency = currency
            self.batchSize = batchSize
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRemittanceRequestView(_ item: PrimaryRemittanceRequest) -> PrimaryRemittanceRequestView {
        return PrimaryRemittanceRequestView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            windowDays: String(item.windowDays),
            currency: item.currency,
            batchSize: String(item.batchSize),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRemittanceRequestViews(_ items: [PrimaryRemittanceRequest]) -> [PrimaryRemittanceRequestView] {
        var views: [PrimaryRemittanceRequestView] = []
        for item in items {
            views.append(toPrimaryRemittanceRequestView(item))
        }
        return views
    }

    static func sumPrimaryRemittanceRequestView(_ view: PrimaryRemittanceRequestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize) + parsedAmount
    }
}
