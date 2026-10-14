import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol tier.
    final class CareProtocolTierView {
        var code: String
        var titleText: String
        var patientRefText: String
        var amount: String
        var name: String
        var country: String
        var label: String
        var payerText: String
        var ward: String
        var diagnosisCodeText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, titleText: String, patientRefText: String, amount: String, name: String, country: String, label: String, payerText: String, ward: String, diagnosisCodeText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.patientRefText = patientRefText
            self.amount = amount
            self.name = name
            self.country = country
            self.label = label
            self.payerText = payerText
            self.ward = ward
            self.diagnosisCodeText = diagnosisCodeText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolTierView(_ item: CareProtocolTier) -> CareProtocolTierView {
        return CareProtocolTierView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            amount: String(format: "%.2f", item.amount),
            name: Kit.Text.truncate(item.name, limit: 64),
            country: item.country,
            label: Kit.Text.truncate(item.label, limit: 40),
            payerText: item.payer,
            ward: item.ward,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolTierViews(_ items: [CareProtocolTier]) -> [CareProtocolTierView] {
        var views: [CareProtocolTierView] = []
        for item in items {
            views.append(toCareProtocolTierView(item))
        }
        return views
    }

    static func sumCareProtocolTierView(_ view: CareProtocolTierView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedAmount + Double(parsedDurationMinutes)
    }
}
