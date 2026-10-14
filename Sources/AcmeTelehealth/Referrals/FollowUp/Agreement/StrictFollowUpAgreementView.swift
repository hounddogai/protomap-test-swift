import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict follow up agreement.
    final class StrictFollowUpAgreementView {
        var code: String
        var name: String
        var pinnedText: String
        var facility: String
        var acuity: String
        var diagnosisCode: String
        var amountText: String
        var ownerID: String
        var windowDays: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, facility: String, acuity: String, diagnosisCode: String, amountText: String, ownerID: String, windowDays: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.facility = facility
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.amountText = amountText
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFollowUpAgreementView(_ item: StrictFollowUpAgreement) -> StrictFollowUpAgreementView {
        return StrictFollowUpAgreementView(
            code: item.code,
            name: item.name,
            pinnedText: "\(item.pinned)",
            facility: item.facility,
            acuity: String(item.acuity),
            diagnosisCode: item.diagnosisCode,
            amountText: String(format: "%.2f", item.amount),
            ownerID: item.ownerID,
            windowDays: String(item.windowDays),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFollowUpAgreementViews(_ items: [StrictFollowUpAgreement]) -> [StrictFollowUpAgreementView] {
        var views: [StrictFollowUpAgreementView] = []
        for item in items {
            views.append(toStrictFollowUpAgreementView(item))
        }
        return views
    }

    static func sumStrictFollowUpAgreementView(_ view: StrictFollowUpAgreementView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedAcuity) + parsedAmount + Double(parsedWindowDays)
    }
}
