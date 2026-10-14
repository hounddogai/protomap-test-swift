import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending cleaning preference.
    final class PendingCleaningPreferenceView {
        var code: String
        var labelText: String
        var retries: String
        var currency: String
        var externalRef: String
        var floorValue: String
        var expiresAt: String
        var channel: String
        var copayText: String
        var priorityText: String
        var statusLabel: String

        init(code: String, labelText: String, retries: String, currency: String, externalRef: String, floorValue: String, expiresAt: String, channel: String, copayText: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.retries = retries
            self.currency = currency
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.channel = channel
            self.copayText = copayText
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCleaningPreferenceView(_ item: PendingCleaningPreference) -> PendingCleaningPreferenceView {
        return PendingCleaningPreferenceView(
            code: item.code,
            labelText: item.label,
            retries: String(item.retries),
            currency: item.currency,
            externalRef: item.externalRef,
            floorValue: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            channel: item.channel,
            copayText: String(format: "%.2f", item.copay),
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCleaningPreferenceViews(_ items: [PendingCleaningPreference]) -> [PendingCleaningPreferenceView] {
        var views: [PendingCleaningPreferenceView] = []
        for item in items {
            views.append(toPendingCleaningPreferenceView(item))
        }
        return views
    }

    static func sumPendingCleaningPreferenceView(_ view: PendingCleaningPreferenceView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRetries) + parsedFloorValue + Double(parsedExpiresAt)
    }
}
