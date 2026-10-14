import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default panel override.
    final class DefaultPanelOverrideView {
        var codeText: String
        var name: String
        var thresholdText: String
        var quantityText: String
        var ownerID: String
        var retries: String
        var contactEmail: String
        var timezoneText: String
        var titleText: String
        var statusLabel: String

        init(codeText: String, name: String, thresholdText: String, quantityText: String, ownerID: String, retries: String, contactEmail: String, timezoneText: String, titleText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.thresholdText = thresholdText
            self.quantityText = quantityText
            self.ownerID = ownerID
            self.retries = retries
            self.contactEmail = contactEmail
            self.timezoneText = timezoneText
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultPanelOverrideView(_ item: DefaultPanelOverride) -> DefaultPanelOverrideView {
        return DefaultPanelOverrideView(
            codeText: item.code,
            name: item.name,
            thresholdText: String(format: "%.2f", item.threshold),
            quantityText: String(item.quantity),
            ownerID: item.ownerID,
            retries: String(item.retries),
            contactEmail: item.contactEmail,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            titleText: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultPanelOverrideViews(_ items: [DefaultPanelOverride]) -> [DefaultPanelOverrideView] {
        var views: [DefaultPanelOverrideView] = []
        for item in items {
            views.append(toDefaultPanelOverrideView(item))
        }
        return views
    }

    static func sumDefaultPanelOverrideView(_ view: DefaultPanelOverrideView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedThreshold + Double(parsedQuantity) + Double(parsedRetries)
    }
}
