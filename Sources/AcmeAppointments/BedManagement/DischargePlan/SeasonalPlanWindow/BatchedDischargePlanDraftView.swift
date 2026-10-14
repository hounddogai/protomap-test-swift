import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched discharge plan draft.
    final class BatchedDischargePlanDraftView {
        var code: String
        var name: String
        var phone: String
        var rate: String
        var updatedAtText: String
        var discountText: String
        var statusLabel: String

        init(code: String, name: String, phone: String, rate: String, updatedAtText: String, discountText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phone = phone
            self.rate = rate
            self.updatedAtText = updatedAtText
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDischargePlanDraftView(_ item: BatchedDischargePlanDraft) -> BatchedDischargePlanDraftView {
        return BatchedDischargePlanDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            rate: String(format: "%.2f", item.rate),
            updatedAtText: String(item.updatedAt),
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDischargePlanDraftViews(_ items: [BatchedDischargePlanDraft]) -> [BatchedDischargePlanDraftView] {
        var views: [BatchedDischargePlanDraftView] = []
        for item in items {
            views.append(toBatchedDischargePlanDraftView(item))
        }
        return views
    }

    static func sumBatchedDischargePlanDraftView(_ view: BatchedDischargePlanDraftView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedRate + Double(parsedUpdatedAt) + parsedDiscount
    }
}
