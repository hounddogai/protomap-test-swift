import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up reservation.
    final class FollowUpReservationView {
        var code: String
        var name: String
        var wardText: String
        var discount: String
        var titleText: String
        var copay: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, wardText: String, discount: String, titleText: String, copay: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.wardText = wardText
            self.discount = discount
            self.titleText = titleText
            self.copay = copay
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpReservationView(_ item: FollowUpReservation) -> FollowUpReservationView {
        return FollowUpReservationView(
            code: item.code,
            name: item.name,
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            discount: String(format: "%.2f", item.discount),
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpReservationViews(_ items: [FollowUpReservation]) -> [FollowUpReservationView] {
        var views: [FollowUpReservationView] = []
        for item in items {
            views.append(toFollowUpReservationView(item))
        }
        return views
    }

    static func sumFollowUpReservationView(_ view: FollowUpReservationView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + parsedCopay + Double(parsedCreatedAt)
    }
}
