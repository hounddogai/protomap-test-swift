import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy cycle.
    final class ProxyCycleView {
        var code: String
        var nameText: String
        var summary: String
        var floorValueText: String
        var minimum: String
        var channel: String
        var labelText: String
        var approved: String
        var statusLabel: String

        init(code: String, nameText: String, summary: String, floorValueText: String, minimum: String, channel: String, labelText: String, approved: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.summary = summary
            self.floorValueText = floorValueText
            self.minimum = minimum
            self.channel = channel
            self.labelText = labelText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toProxyCycleView(_ item: ProxyCycle) -> ProxyCycleView {
        return ProxyCycleView(
            code: item.code,
            nameText: item.name,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            floorValueText: String(format: "%.2f", item.floorValue),
            minimum: String(format: "%.2f", item.minimum),
            channel: item.channel,
            labelText: item.label,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyCycleViews(_ items: [ProxyCycle]) -> [ProxyCycleView] {
        var views: [ProxyCycleView] = []
        for item in items {
            views.append(toProxyCycleView(item))
        }
        return views
    }

    static func sumProxyCycleView(_ view: ProxyCycleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedFloorValue + parsedMinimum
    }
}
