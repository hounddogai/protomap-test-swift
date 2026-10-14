import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert preference.
    final class AlertPreferenceView {
        var code: String
        var label: String
        var timezoneText: String
        var region: String
        var quantityText: String
        var phoneText: String
        var batchSize: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, region: String, quantityText: String, phoneText: String, batchSize: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.region = region
            self.quantityText = quantityText
            self.phoneText = phoneText
            self.batchSize = batchSize
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAlertPreferenceView(_ item: AlertPreference) -> AlertPreferenceView {
        return AlertPreferenceView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 80),
            region: Kit.Text.truncate(item.region, limit: 64),
            quantityText: String(item.quantity),
            phoneText: item.phone,
            batchSize: String(item.batchSize),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertPreferenceViews(_ items: [AlertPreference]) -> [AlertPreferenceView] {
        var views: [AlertPreferenceView] = []
        for item in items {
            views.append(toAlertPreferenceView(item))
        }
        return views
    }

    static func sumAlertPreferenceView(_ view: AlertPreferenceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedQuantity) + Double(parsedBatchSize) + Double(parsedStartsAt)
    }
}
