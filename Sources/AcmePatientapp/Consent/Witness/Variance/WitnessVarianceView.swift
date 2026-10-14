import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness variance.
    final class WitnessVarianceView {
        var code: String
        var labelText: String
        var encounterID: String
        var timezone: String
        var contactEmail: String
        var ratio: String
        var retries: String
        var summary: String
        var endsAt: String
        var capacity: String
        var graceDays: String
        var statusLabel: String

        init(code: String, labelText: String, encounterID: String, timezone: String, contactEmail: String, ratio: String, retries: String, summary: String, endsAt: String, capacity: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.encounterID = encounterID
            self.timezone = timezone
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.retries = retries
            self.summary = summary
            self.endsAt = endsAt
            self.capacity = capacity
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessVarianceView(_ item: WitnessVariance) -> WitnessVarianceView {
        return WitnessVarianceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            encounterID: item.encounterID,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            summary: item.summary,
            endsAt: String(item.endsAt),
            capacity: String(item.capacity),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessVarianceViews(_ items: [WitnessVariance]) -> [WitnessVarianceView] {
        var views: [WitnessVarianceView] = []
        for item in items {
            views.append(toWitnessVarianceView(item))
        }
        return views
    }

    static func sumWitnessVarianceView(_ view: WitnessVarianceView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedRatio + Double(parsedRetries) + Double(parsedEndsAt)
    }
}
