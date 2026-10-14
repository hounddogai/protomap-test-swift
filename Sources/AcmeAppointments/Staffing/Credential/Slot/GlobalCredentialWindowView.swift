import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global credential window.
    final class GlobalCredentialWindowView {
        var code: String
        var label: String
        var contactEmail: String
        var payerText: String
        var notesText: String
        var retries: String
        var countryText: String
        var encounterID: String
        var maximumText: String
        var unit: String
        var costText: String
        var statusLabel: String

        init(code: String, label: String, contactEmail: String, payerText: String, notesText: String, retries: String, countryText: String, encounterID: String, maximumText: String, unit: String, costText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.payerText = payerText
            self.notesText = notesText
            self.retries = retries
            self.countryText = countryText
            self.encounterID = encounterID
            self.maximumText = maximumText
            self.unit = unit
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCredentialWindowView(_ item: GlobalCredentialWindow) -> GlobalCredentialWindowView {
        return GlobalCredentialWindowView(
            code: item.code,
            label: item.label,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            payerText: item.payer,
            notesText: Kit.Text.truncate(item.notes, limit: 80),
            retries: String(item.retries),
            countryText: item.country,
            encounterID: item.encounterID,
            maximumText: String(format: "%.2f", item.maximum),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCredentialWindowViews(_ items: [GlobalCredentialWindow]) -> [GlobalCredentialWindowView] {
        var views: [GlobalCredentialWindowView] = []
        for item in items {
            views.append(toGlobalCredentialWindowView(item))
        }
        return views
    }

    static func sumGlobalCredentialWindowView(_ view: GlobalCredentialWindowView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRetries) + parsedMaximum + parsedCost
    }
}
