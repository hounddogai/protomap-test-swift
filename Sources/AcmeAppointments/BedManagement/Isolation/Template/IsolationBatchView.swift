import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation batch.
    final class IsolationBatchView {
        var code: String
        var label: String
        var rateText: String
        var checksumText: String
        var amountText: String
        var bedText: String
        var procedureCodeText: String
        var allergyText: String
        var updatedAt: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, rateText: String, checksumText: String, amountText: String, bedText: String, procedureCodeText: String, allergyText: String, updatedAt: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rateText = rateText
            self.checksumText = checksumText
            self.amountText = amountText
            self.bedText = bedText
            self.procedureCodeText = procedureCodeText
            self.allergyText = allergyText
            self.updatedAt = updatedAt
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationBatchView(_ item: IsolationBatch) -> IsolationBatchView {
        return IsolationBatchView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            amountText: String(format: "%.2f", item.amount),
            bedText: Kit.Text.truncate(item.bed, limit: 64),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            allergyText: item.allergy,
            updatedAt: String(item.updatedAt),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationBatchViews(_ items: [IsolationBatch]) -> [IsolationBatchView] {
        var views: [IsolationBatchView] = []
        for item in items {
            views.append(toIsolationBatchView(item))
        }
        return views
    }

    static func sumIsolationBatchView(_ view: IsolationBatchView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedRate + parsedAmount + Double(parsedUpdatedAt)
    }
}
