import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted assessment request.
    final class WeightedAssessmentRequestView {
        var codeText: String
        var titleText: String
        var specialtyText: String
        var endsAtText: String
        var capacity: String
        var rate: String
        var nameText: String
        var discountText: String
        var payer: String
        var phone: String
        var statusLabel: String

        init(codeText: String, titleText: String, specialtyText: String, endsAtText: String, capacity: String, rate: String, nameText: String, discountText: String, payer: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.specialtyText = specialtyText
            self.endsAtText = endsAtText
            self.capacity = capacity
            self.rate = rate
            self.nameText = nameText
            self.discountText = discountText
            self.payer = payer
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAssessmentRequestView(_ item: WeightedAssessmentRequest) -> WeightedAssessmentRequestView {
        return WeightedAssessmentRequestView(
            codeText: item.code,
            titleText: item.title,
            specialtyText: item.specialty,
            endsAtText: String(item.endsAt),
            capacity: String(item.capacity),
            rate: String(format: "%.2f", item.rate),
            nameText: item.name,
            discountText: String(format: "%.2f", item.discount),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAssessmentRequestViews(_ items: [WeightedAssessmentRequest]) -> [WeightedAssessmentRequestView] {
        var views: [WeightedAssessmentRequestView] = []
        for item in items {
            views.append(toWeightedAssessmentRequestView(item))
        }
        return views
    }

    static func sumWeightedAssessmentRequestView(_ view: WeightedAssessmentRequestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCapacity) + parsedRate
    }
}
