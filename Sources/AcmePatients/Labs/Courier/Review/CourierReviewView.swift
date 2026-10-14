import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier review.
    final class CourierReviewView {
        var code: String
        var nameText: String
        var minimum: String
        var weightText: String
        var unitText: String
        var discount: String
        var titleText: String
        var checksum: String
        var allergyText: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, nameText: String, minimum: String, weightText: String, unitText: String, discount: String, titleText: String, checksum: String, allergyText: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.minimum = minimum
            self.weightText = weightText
            self.unitText = unitText
            self.discount = discount
            self.titleText = titleText
            self.checksum = checksum
            self.allergyText = allergyText
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierReviewView(_ item: CourierReview) -> CourierReviewView {
        return CourierReviewView(
            code: item.code,
            nameText: item.name,
            minimum: String(format: "%.2f", item.minimum),
            weightText: String(format: "%.2f", item.weight),
            unitText: item.unit,
            discount: String(format: "%.2f", item.discount),
            titleText: item.title,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            allergyText: item.allergy,
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierReviewViews(_ items: [CourierReview]) -> [CourierReviewView] {
        var views: [CourierReviewView] = []
        for item in items {
            views.append(toCourierReviewView(item))
        }
        return views
    }

    static func sumCourierReviewView(_ view: CourierReviewView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedMinimum + parsedWeight + parsedDiscount
    }
}
