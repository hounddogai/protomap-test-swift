import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential request.
    final class CredentialRequestView {
        var code: String
        var titleText: String
        var diagnosisCode: String
        var quantity: String
        var refills: String
        var visitMinutesText: String
        var approved: String
        var budget: String
        var checksumText: String
        var country: String
        var statusLabel: String

        init(code: String, titleText: String, diagnosisCode: String, quantity: String, refills: String, visitMinutesText: String, approved: String, budget: String, checksumText: String, country: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.refills = refills
            self.visitMinutesText = visitMinutesText
            self.approved = approved
            self.budget = budget
            self.checksumText = checksumText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialRequestView(_ item: CredentialRequest) -> CredentialRequestView {
        return CredentialRequestView(
            code: item.code,
            titleText: item.title,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            quantity: String(item.quantity),
            refills: String(item.refills),
            visitMinutesText: String(item.visitMinutes),
            approved: "\(item.approved)",
            budget: String(format: "%.2f", item.budget),
            checksumText: item.checksum,
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialRequestViews(_ items: [CredentialRequest]) -> [CredentialRequestView] {
        var views: [CredentialRequestView] = []
        for item in items {
            views.append(toCredentialRequestView(item))
        }
        return views
    }

    static func sumCredentialRequestView(_ view: CredentialRequestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRefills) + Double(parsedVisitMinutes)
    }
}
