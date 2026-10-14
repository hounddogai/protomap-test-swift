import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global consent form template.
    final class GlobalConsentFormTemplateView {
        var code: String
        var name: String
        var ratio: String
        var phone: String
        var clinicianID: String
        var amount: String
        var copayText: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, phone: String, clinicianID: String, amount: String, copayText: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.phone = phone
            self.clinicianID = clinicianID
            self.amount = amount
            self.copayText = copayText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalConsentFormTemplateView(_ item: GlobalConsentFormTemplate) -> GlobalConsentFormTemplateView {
        return GlobalConsentFormTemplateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            phone: item.phone,
            clinicianID: item.clinicianID,
            amount: String(format: "%.2f", item.amount),
            copayText: String(format: "%.2f", item.copay),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalConsentFormTemplateViews(_ items: [GlobalConsentFormTemplate]) -> [GlobalConsentFormTemplateView] {
        var views: [GlobalConsentFormTemplateView] = []
        for item in items {
            views.append(toGlobalConsentFormTemplateView(item))
        }
        return views
    }

    static func sumGlobalConsentFormTemplateView(_ view: GlobalConsentFormTemplateView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedRatio + parsedAmount + parsedCopay
    }
}
