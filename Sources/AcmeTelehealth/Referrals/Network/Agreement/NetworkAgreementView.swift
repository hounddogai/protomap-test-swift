import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network agreement.
    final class NetworkAgreementView {
        var code: String
        var label: String
        var rateText: String
        var attempts: String
        var clinicianID: String
        var externalRef: String
        var contactEmail: String
        var patientRef: String
        var costText: String
        var expiresAt: String
        var regionText: String
        var statusLabel: String

        init(code: String, label: String, rateText: String, attempts: String, clinicianID: String, externalRef: String, contactEmail: String, patientRef: String, costText: String, expiresAt: String, regionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rateText = rateText
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.externalRef = externalRef
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.costText = costText
            self.expiresAt = expiresAt
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkAgreementView(_ item: NetworkAgreement) -> NetworkAgreementView {
        return NetworkAgreementView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            attempts: String(item.attempts),
            clinicianID: item.clinicianID,
            externalRef: item.externalRef,
            contactEmail: item.contactEmail,
            patientRef: item.patientRef,
            costText: String(format: "%.2f", item.cost),
            expiresAt: String(item.expiresAt),
            regionText: Kit.Text.truncate(item.region, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkAgreementViews(_ items: [NetworkAgreement]) -> [NetworkAgreementView] {
        var views: [NetworkAgreementView] = []
        for item in items {
            views.append(toNetworkAgreementView(item))
        }
        return views
    }

    static func sumNetworkAgreementView(_ view: NetworkAgreementView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedRate + Double(parsedAttempts) + parsedCost
    }
}
