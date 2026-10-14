import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched disclosure plan.
    final class BatchedDisclosurePlanView {
        var code: String
        var titleText: String
        var phoneText: String
        var copay: String
        var updatedAt: String
        var wardText: String
        var statusLabel: String

        init(code: String, titleText: String, phoneText: String, copay: String, updatedAt: String, wardText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.phoneText = phoneText
            self.copay = copay
            self.updatedAt = updatedAt
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDisclosurePlanView(_ item: BatchedDisclosurePlan) -> BatchedDisclosurePlanView {
        return BatchedDisclosurePlanView(
            code: item.code,
            titleText: item.title,
            phoneText: item.phone,
            copay: String(format: "%.2f", item.copay),
            updatedAt: String(item.updatedAt),
            wardText: Kit.Text.truncate(item.ward, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDisclosurePlanViews(_ items: [BatchedDisclosurePlan]) -> [BatchedDisclosurePlanView] {
        var views: [BatchedDisclosurePlanView] = []
        for item in items {
            views.append(toBatchedDisclosurePlanView(item))
        }
        return views
    }

    static func sumBatchedDisclosurePlanView(_ view: BatchedDisclosurePlanView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedCopay + Double(parsedUpdatedAt)
    }
}
