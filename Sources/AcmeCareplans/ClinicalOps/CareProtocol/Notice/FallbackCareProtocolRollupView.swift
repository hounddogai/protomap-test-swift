import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback care protocol rollup.
    final class FallbackCareProtocolRollupView {
        var code: String
        var title: String
        var retries: String
        var minimumText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, title: String, retries: String, minimumText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retries = retries
            self.minimumText = minimumText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolRollupView(_ item: FallbackCareProtocolRollup) -> FallbackCareProtocolRollupView {
        return FallbackCareProtocolRollupView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            retries: String(item.retries),
            minimumText: String(format: "%.2f", item.minimum),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolRollupViews(_ items: [FallbackCareProtocolRollup]) -> [FallbackCareProtocolRollupView] {
        var views: [FallbackCareProtocolRollupView] = []
        for item in items {
            views.append(toFallbackCareProtocolRollupView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolRollupView(_ view: FallbackCareProtocolRollupView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedRetries) + parsedMinimum + Double(parsedUpdatedAt)
    }
}
