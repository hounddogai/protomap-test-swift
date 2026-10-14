import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall threshold.
    final class RecallThresholdView {
        var code: String
        var name: String
        var facility: String
        var maximum: String
        var ratio: String
        var encounterID: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, facility: String, maximum: String, ratio: String, encounterID: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facility = facility
            self.maximum = maximum
            self.ratio = ratio
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRecallThresholdView(_ item: RecallThreshold) -> RecallThresholdView {
        return RecallThresholdView(
            code: item.code,
            name: item.name,
            facility: item.facility,
            maximum: String(format: "%.2f", item.maximum),
            ratio: String(format: "%.2f", item.ratio),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallThresholdViews(_ items: [RecallThreshold]) -> [RecallThresholdView] {
        var views: [RecallThresholdView] = []
        for item in items {
            views.append(toRecallThresholdView(item))
        }
        return views
    }

    static func sumRecallThresholdView(_ view: RecallThresholdView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMaximum + parsedRatio + Double(parsedEndsAt)
    }
}
