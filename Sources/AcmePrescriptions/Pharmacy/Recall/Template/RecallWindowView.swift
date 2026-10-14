import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall window.
    final class RecallWindowView {
        var code: String
        var title: String
        var reviewerText: String
        var discountText: String
        var marginText: String
        var patientRef: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, reviewerText: String, discountText: String, marginText: String, patientRef: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewerText = reviewerText
            self.discountText = discountText
            self.marginText = marginText
            self.patientRef = patientRef
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toRecallWindowView(_ item: RecallWindow) -> RecallWindowView {
        return RecallWindowView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            reviewerText: item.reviewer,
            discountText: String(format: "%.2f", item.discount),
            marginText: String(format: "%.2f", item.margin),
            patientRef: item.patientRef,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallWindowViews(_ items: [RecallWindow]) -> [RecallWindowView] {
        var views: [RecallWindowView] = []
        for item in items {
            views.append(toRecallWindowView(item))
        }
        return views
    }

    static func sumRecallWindowView(_ view: RecallWindowView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedDiscount + parsedMargin
    }
}
