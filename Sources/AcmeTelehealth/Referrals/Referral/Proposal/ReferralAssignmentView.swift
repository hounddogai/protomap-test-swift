import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral assignment.
    final class ReferralAssignmentView {
        var codeText: String
        var titleText: String
        var name: String
        var patientRef: String
        var segment: String
        var countryText: String
        var unit: String
        var procedureCode: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, titleText: String, name: String, patientRef: String, segment: String, countryText: String, unit: String, procedureCode: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.name = name
            self.patientRef = patientRef
            self.segment = segment
            self.countryText = countryText
            self.unit = unit
            self.procedureCode = procedureCode
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toReferralAssignmentView(_ item: ReferralAssignment) -> ReferralAssignmentView {
        return ReferralAssignmentView(
            codeText: item.code,
            titleText: item.title,
            name: item.name,
            patientRef: item.patientRef,
            segment: item.segment,
            countryText: item.country,
            unit: item.unit,
            procedureCode: item.procedureCode,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralAssignmentViews(_ items: [ReferralAssignment]) -> [ReferralAssignmentView] {
        var views: [ReferralAssignmentView] = []
        for item in items {
            views.append(toReferralAssignmentView(item))
        }
        return views
    }

    static func sumReferralAssignmentView(_ view: ReferralAssignmentView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
