import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient worklist group.
    final class LenientWorklistGroupView {
        var code: String
        var label: String
        var category: String
        var reviewerText: String
        var acuity: String
        var limit: String
        var endsAt: String
        var phone: String
        var visibleText: String
        var maximum: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, category: String, reviewerText: String, acuity: String, limit: String, endsAt: String, phone: String, visibleText: String, maximum: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.category = category
            self.reviewerText = reviewerText
            self.acuity = acuity
            self.limit = limit
            self.endsAt = endsAt
            self.phone = phone
            self.visibleText = visibleText
            self.maximum = maximum
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientWorklistGroupView(_ item: LenientWorklistGroup) -> LenientWorklistGroupView {
        return LenientWorklistGroupView(
            code: item.code,
            label: item.label,
            category: Kit.Text.truncate(item.category, limit: 64),
            reviewerText: item.reviewer,
            acuity: String(item.acuity),
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            phone: item.phone,
            visibleText: "\(item.visible)",
            maximum: String(format: "%.2f", item.maximum),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientWorklistGroupViews(_ items: [LenientWorklistGroup]) -> [LenientWorklistGroupView] {
        var views: [LenientWorklistGroupView] = []
        for item in items {
            views.append(toLenientWorklistGroupView(item))
        }
        return views
    }

    static func sumLenientWorklistGroupView(_ view: LenientWorklistGroupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedLimit) + Double(parsedEndsAt)
    }
}
