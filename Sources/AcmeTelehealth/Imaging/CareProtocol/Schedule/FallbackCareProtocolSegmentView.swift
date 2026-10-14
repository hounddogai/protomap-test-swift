import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback care protocol segment.
    final class FallbackCareProtocolSegmentView {
        var code: String
        var titleText: String
        var summaryText: String
        var country: String
        var batchSize: String
        var statusLabel: String

        init(code: String, titleText: String, summaryText: String, country: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.summaryText = summaryText
            self.country = country
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolSegmentView(_ item: FallbackCareProtocolSegment) -> FallbackCareProtocolSegmentView {
        return FallbackCareProtocolSegmentView(
            code: item.code,
            titleText: item.title,
            summaryText: item.summary,
            country: item.country,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolSegmentViews(_ items: [FallbackCareProtocolSegment]) -> [FallbackCareProtocolSegmentView] {
        var views: [FallbackCareProtocolSegmentView] = []
        for item in items {
            views.append(toFallbackCareProtocolSegmentView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolSegmentView(_ view: FallbackCareProtocolSegmentView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
