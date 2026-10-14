import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential window.
    final class CredentialWindowView {
        var code: String
        var label: String
        var costText: String
        var timezoneText: String
        var discount: String
        var description: String
        var segmentText: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, label: String, costText: String, timezoneText: String, discount: String, description: String, segmentText: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.costText = costText
            self.timezoneText = timezoneText
            self.discount = discount
            self.description = description
            self.segmentText = segmentText
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialWindowView(_ item: CredentialWindow) -> CredentialWindowView {
        return CredentialWindowView(
            code: item.code,
            label: item.label,
            costText: String(format: "%.2f", item.cost),
            timezoneText: item.timezone,
            discount: String(format: "%.2f", item.discount),
            description: Kit.Text.truncate(item.description, limit: 120),
            segmentText: item.segment,
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialWindowViews(_ items: [CredentialWindow]) -> [CredentialWindowView] {
        var views: [CredentialWindowView] = []
        for item in items {
            views.append(toCredentialWindowView(item))
        }
        return views
    }

    static func sumCredentialWindowView(_ view: CredentialWindowView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCost + parsedDiscount
    }
}
