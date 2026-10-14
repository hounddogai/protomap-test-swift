import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default charge request.
    final class DefaultChargeRequestView {
        var codeText: String
        var name: String
        var phone: String
        var ceiling: String
        var countryText: String
        var reviewerText: String
        var dosageMg: String
        var encounterIDText: String
        var minimum: String
        var payer: String
        var labelText: String
        var statusLabel: String

        init(codeText: String, name: String, phone: String, ceiling: String, countryText: String, reviewerText: String, dosageMg: String, encounterIDText: String, minimum: String, payer: String, labelText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.phone = phone
            self.ceiling = ceiling
            self.countryText = countryText
            self.reviewerText = reviewerText
            self.dosageMg = dosageMg
            self.encounterIDText = encounterIDText
            self.minimum = minimum
            self.payer = payer
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultChargeRequestView(_ item: DefaultChargeRequest) -> DefaultChargeRequestView {
        return DefaultChargeRequestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            phone: item.phone,
            ceiling: String(format: "%.2f", item.ceiling),
            countryText: item.country,
            reviewerText: item.reviewer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            encounterIDText: item.encounterID,
            minimum: String(format: "%.2f", item.minimum),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultChargeRequestViews(_ items: [DefaultChargeRequest]) -> [DefaultChargeRequestView] {
        var views: [DefaultChargeRequestView] = []
        for item in items {
            views.append(toDefaultChargeRequestView(item))
        }
        return views
    }

    static func sumDefaultChargeRequestView(_ view: DefaultChargeRequestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedCeiling + parsedDosageMg + parsedMinimum
    }
}
