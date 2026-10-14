import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution request.
    final class SubstitutionRequestView {
        var code: String
        var titleText: String
        var durationMinutes: String
        var locale: String
        var quantity: String
        var pinned: String
        var approved: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, titleText: String, durationMinutes: String, locale: String, quantity: String, pinned: String, approved: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.durationMinutes = durationMinutes
            self.locale = locale
            self.quantity = quantity
            self.pinned = pinned
            self.approved = approved
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionRequestView(_ item: SubstitutionRequest) -> SubstitutionRequestView {
        return SubstitutionRequestView(
            code: item.code,
            titleText: item.title,
            durationMinutes: String(item.durationMinutes),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            quantity: String(item.quantity),
            pinned: "\(item.pinned)",
            approved: "\(item.approved)",
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionRequestViews(_ items: [SubstitutionRequest]) -> [SubstitutionRequestView] {
        var views: [SubstitutionRequestView] = []
        for item in items {
            views.append(toSubstitutionRequestView(item))
        }
        return views
    }

    static func sumSubstitutionRequestView(_ view: SubstitutionRequestView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedQuantity)
    }
}
