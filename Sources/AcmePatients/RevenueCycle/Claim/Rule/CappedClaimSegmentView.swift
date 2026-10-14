import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped claim segment.
    final class CappedClaimSegmentView {
        var code: String
        var titleText: String
        var notesText: String
        var ratio: String
        var createdAt: String
        var statusLabel: String

        init(code: String, titleText: String, notesText: String, ratio: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.notesText = notesText
            self.ratio = ratio
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClaimSegmentView(_ item: CappedClaimSegment) -> CappedClaimSegmentView {
        return CappedClaimSegmentView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            notesText: item.notes,
            ratio: String(format: "%.2f", item.ratio),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClaimSegmentViews(_ items: [CappedClaimSegment]) -> [CappedClaimSegmentView] {
        var views: [CappedClaimSegmentView] = []
        for item in items {
            views.append(toCappedClaimSegmentView(item))
        }
        return views
    }

    static func sumCappedClaimSegmentView(_ view: CappedClaimSegmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedRatio + Double(parsedCreatedAt)
    }
}
