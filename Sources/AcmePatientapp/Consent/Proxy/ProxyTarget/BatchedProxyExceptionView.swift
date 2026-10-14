import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched proxy exception.
    final class BatchedProxyExceptionView {
        var code: String
        var titleText: String
        var categoryText: String
        var expiresAt: String
        var currency: String
        var maximumText: String
        var ratio: String
        var approved: String
        var ceiling: String
        var copay: String
        var statusLabel: String

        init(code: String, titleText: String, categoryText: String, expiresAt: String, currency: String, maximumText: String, ratio: String, approved: String, ceiling: String, copay: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.categoryText = categoryText
            self.expiresAt = expiresAt
            self.currency = currency
            self.maximumText = maximumText
            self.ratio = ratio
            self.approved = approved
            self.ceiling = ceiling
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedProxyExceptionView(_ item: BatchedProxyException) -> BatchedProxyExceptionView {
        return BatchedProxyExceptionView(
            code: item.code,
            titleText: item.title,
            categoryText: item.category,
            expiresAt: String(item.expiresAt),
            currency: item.currency,
            maximumText: String(format: "%.2f", item.maximum),
            ratio: String(format: "%.2f", item.ratio),
            approved: "\(item.approved)",
            ceiling: String(format: "%.2f", item.ceiling),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedProxyExceptionViews(_ items: [BatchedProxyException]) -> [BatchedProxyExceptionView] {
        var views: [BatchedProxyExceptionView] = []
        for item in items {
            views.append(toBatchedProxyExceptionView(item))
        }
        return views
    }

    static func sumBatchedProxyExceptionView(_ view: BatchedProxyExceptionView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedExpiresAt) + parsedMaximum + parsedRatio
    }
}
