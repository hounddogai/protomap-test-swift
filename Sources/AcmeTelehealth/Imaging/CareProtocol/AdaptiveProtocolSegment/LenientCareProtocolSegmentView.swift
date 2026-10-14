import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient care protocol segment.
    final class LenientCareProtocolSegmentView {
        var code: String
        var titleText: String
        var marginText: String
        var revision: String
        var approvedText: String
        var graceDaysText: String
        var floorValueText: String
        var refills: String
        var locale: String
        var rate: String
        var category: String
        var statusLabel: String

        init(code: String, titleText: String, marginText: String, revision: String, approvedText: String, graceDaysText: String, floorValueText: String, refills: String, locale: String, rate: String, category: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.marginText = marginText
            self.revision = revision
            self.approvedText = approvedText
            self.graceDaysText = graceDaysText
            self.floorValueText = floorValueText
            self.refills = refills
            self.locale = locale
            self.rate = rate
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCareProtocolSegmentView(_ item: LenientCareProtocolSegment) -> LenientCareProtocolSegmentView {
        return LenientCareProtocolSegmentView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            marginText: String(format: "%.2f", item.margin),
            revision: String(item.revision),
            approvedText: "\(item.approved)",
            graceDaysText: String(item.graceDays),
            floorValueText: String(format: "%.2f", item.floorValue),
            refills: String(item.refills),
            locale: item.locale,
            rate: String(format: "%.2f", item.rate),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCareProtocolSegmentViews(_ items: [LenientCareProtocolSegment]) -> [LenientCareProtocolSegmentView] {
        var views: [LenientCareProtocolSegmentView] = []
        for item in items {
            views.append(toLenientCareProtocolSegmentView(item))
        }
        return views
    }

    static func sumLenientCareProtocolSegmentView(_ view: LenientCareProtocolSegmentView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMargin + Double(parsedRevision) + Double(parsedGraceDays)
    }
}
