import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive alert request.
    final class AdaptiveAlertRequestView {
        var codeText: String
        var title: String
        var contactEmailText: String
        var phone: String
        var clinicianIDText: String
        var rate: String
        var summary: String
        var quantity: String
        var country: String
        var statusLabel: String

        init(codeText: String, title: String, contactEmailText: String, phone: String, clinicianIDText: String, rate: String, summary: String, quantity: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.contactEmailText = contactEmailText
            self.phone = phone
            self.clinicianIDText = clinicianIDText
            self.rate = rate
            self.summary = summary
            self.quantity = quantity
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAlertRequestView(_ item: AdaptiveAlertRequest) -> AdaptiveAlertRequestView {
        return AdaptiveAlertRequestView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 64),
            contactEmailText: item.contactEmail,
            phone: item.phone,
            clinicianIDText: item.clinicianID,
            rate: String(format: "%.2f", item.rate),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            quantity: String(item.quantity),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAlertRequestViews(_ items: [AdaptiveAlertRequest]) -> [AdaptiveAlertRequestView] {
        var views: [AdaptiveAlertRequestView] = []
        for item in items {
            views.append(toAdaptiveAlertRequestView(item))
        }
        return views
    }

    static func sumAdaptiveAlertRequestView(_ view: AdaptiveAlertRequestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedRate + Double(parsedQuantity)
    }
}
