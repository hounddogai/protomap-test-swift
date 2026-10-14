import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched consent form override.
    final class BatchedConsentFormOverrideView {
        var code: String
        var title: String
        var batchSize: String
        var ratio: String
        var rateText: String
        var statusLabel: String

        init(code: String, title: String, batchSize: String, ratio: String, rateText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.ratio = ratio
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedConsentFormOverrideView(_ item: BatchedConsentFormOverride) -> BatchedConsentFormOverrideView {
        return BatchedConsentFormOverrideView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            batchSize: String(item.batchSize),
            ratio: String(format: "%.2f", item.ratio),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedConsentFormOverrideViews(_ items: [BatchedConsentFormOverride]) -> [BatchedConsentFormOverrideView] {
        var views: [BatchedConsentFormOverrideView] = []
        for item in items {
            views.append(toBatchedConsentFormOverrideView(item))
        }
        return views
    }

    static func sumBatchedConsentFormOverrideView(_ view: BatchedConsentFormOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedBatchSize) + parsedRatio + parsedRate
    }
}
