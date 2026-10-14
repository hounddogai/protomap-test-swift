import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial segment.
    final class DenialSegmentView {
        var codeText: String
        var title: String
        var summary: String
        var batchSizeText: String
        var procedureCode: String
        var maximum: String
        var activeText: String
        var refills: String
        var locale: String
        var cost: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, title: String, summary: String, batchSizeText: String, procedureCode: String, maximum: String, activeText: String, refills: String, locale: String, cost: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.summary = summary
            self.batchSizeText = batchSizeText
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.activeText = activeText
            self.refills = refills
            self.locale = locale
            self.cost = cost
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toDenialSegmentView(_ item: DenialSegment) -> DenialSegmentView {
        return DenialSegmentView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            summary: item.summary,
            batchSizeText: String(item.batchSize),
            procedureCode: item.procedureCode,
            maximum: String(format: "%.2f", item.maximum),
            activeText: "\(item.active)",
            refills: String(item.refills),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            cost: String(format: "%.2f", item.cost),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialSegmentViews(_ items: [DenialSegment]) -> [DenialSegmentView] {
        var views: [DenialSegmentView] = []
        for item in items {
            views.append(toDenialSegmentView(item))
        }
        return views
    }

    static func sumDenialSegmentView(_ view: DenialSegmentView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedBatchSize) + parsedMaximum + Double(parsedRefills)
    }
}
