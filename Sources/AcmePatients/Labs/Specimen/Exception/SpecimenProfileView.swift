import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen profile.
    final class SpecimenProfileView {
        var code: String
        var name: String
        var payer: String
        var startsAtText: String
        var amountText: String
        var ward: String
        var expiresAt: String
        var batchSize: String
        var reviewerText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, name: String, payer: String, startsAtText: String, amountText: String, ward: String, expiresAt: String, batchSize: String, reviewerText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.payer = payer
            self.startsAtText = startsAtText
            self.amountText = amountText
            self.ward = ward
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.reviewerText = reviewerText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenProfileView(_ item: SpecimenProfile) -> SpecimenProfileView {
        return SpecimenProfileView(
            code: item.code,
            name: item.name,
            payer: item.payer,
            startsAtText: String(item.startsAt),
            amountText: String(format: "%.2f", item.amount),
            ward: item.ward,
            expiresAt: String(item.expiresAt),
            batchSize: String(item.batchSize),
            reviewerText: item.reviewer,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenProfileViews(_ items: [SpecimenProfile]) -> [SpecimenProfileView] {
        var views: [SpecimenProfileView] = []
        for item in items {
            views.append(toSpecimenProfileView(item))
        }
        return views
    }

    static func sumSpecimenProfileView(_ view: SpecimenProfileView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedStartsAt) + parsedAmount + Double(parsedExpiresAt)
    }
}
