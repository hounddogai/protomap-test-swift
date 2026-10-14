import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default courier claim.
    final class DefaultCourierClaimView {
        var code: String
        var nameText: String
        var startsAt: String
        var facilityText: String
        var quantity: String
        var statusLabel: String

        init(code: String, nameText: String, startsAt: String, facilityText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.startsAt = startsAt
            self.facilityText = facilityText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCourierClaimView(_ item: DefaultCourierClaim) -> DefaultCourierClaimView {
        return DefaultCourierClaimView(
            code: item.code,
            nameText: item.name,
            startsAt: String(item.startsAt),
            facilityText: Kit.Text.truncate(item.facility, limit: 40),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCourierClaimViews(_ items: [DefaultCourierClaim]) -> [DefaultCourierClaimView] {
        var views: [DefaultCourierClaimView] = []
        for item in items {
            views.append(toDefaultCourierClaimView(item))
        }
        return views
    }

    static func sumDefaultCourierClaimView(_ view: DefaultCourierClaimView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedQuantity)
    }
}
