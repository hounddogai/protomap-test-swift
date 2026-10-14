import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol override.
    final class CareProtocolOverrideView {
        var code: String
        var label: String
        var windowDays: String
        var limit: String
        var specialty: String
        var minimum: String
        var ceiling: String
        var rate: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, windowDays: String, limit: String, specialty: String, minimum: String, ceiling: String, rate: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.limit = limit
            self.specialty = specialty
            self.minimum = minimum
            self.ceiling = ceiling
            self.rate = rate
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolOverrideView(_ item: CareProtocolOverride) -> CareProtocolOverrideView {
        return CareProtocolOverrideView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 40),
            windowDays: String(item.windowDays),
            limit: String(item.limit),
            specialty: item.specialty,
            minimum: String(format: "%.2f", item.minimum),
            ceiling: String(format: "%.2f", item.ceiling),
            rate: String(format: "%.2f", item.rate),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolOverrideViews(_ items: [CareProtocolOverride]) -> [CareProtocolOverrideView] {
        var views: [CareProtocolOverrideView] = []
        for item in items {
            views.append(toCareProtocolOverrideView(item))
        }
        return views
    }

    static func sumCareProtocolOverrideView(_ view: CareProtocolOverrideView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedLimit) + parsedMinimum
    }
}
