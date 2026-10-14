import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient shift segment.
    final class LenientShiftSegmentView {
        var code: String
        var title: String
        var approved: String
        var createdAt: String
        var refills: String
        var contactEmail: String
        var ratio: String
        var statusLabel: String

        init(code: String, title: String, approved: String, createdAt: String, refills: String, contactEmail: String, ratio: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approved = approved
            self.createdAt = createdAt
            self.refills = refills
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toLenientShiftSegmentView(_ item: LenientShiftSegment) -> LenientShiftSegmentView {
        return LenientShiftSegmentView(
            code: item.code,
            title: item.title,
            approved: "\(item.approved)",
            createdAt: String(item.createdAt),
            refills: String(item.refills),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientShiftSegmentViews(_ items: [LenientShiftSegment]) -> [LenientShiftSegmentView] {
        var views: [LenientShiftSegmentView] = []
        for item in items {
            views.append(toLenientShiftSegmentView(item))
        }
        return views
    }

    static func sumLenientShiftSegmentView(_ view: LenientShiftSegmentView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRefills) + parsedRatio
    }
}
