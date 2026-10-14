import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default interaction profile.
    final class DefaultInteractionProfileView {
        var code: String
        var name: String
        var visible: String
        var windowDays: String
        var activeText: String
        var floorValue: String
        var version: String
        var weightText: String
        var regionText: String
        var statusLabel: String

        init(code: String, name: String, visible: String, windowDays: String, activeText: String, floorValue: String, version: String, weightText: String, regionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visible = visible
            self.windowDays = windowDays
            self.activeText = activeText
            self.floorValue = floorValue
            self.version = version
            self.weightText = weightText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultInteractionProfileView(_ item: DefaultInteractionProfile) -> DefaultInteractionProfileView {
        return DefaultInteractionProfileView(
            code: item.code,
            name: item.name,
            visible: "\(item.visible)",
            windowDays: String(item.windowDays),
            activeText: "\(item.active)",
            floorValue: String(format: "%.2f", item.floorValue),
            version: String(item.version),
            weightText: String(format: "%.2f", item.weight),
            regionText: Kit.Text.truncate(item.region, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultInteractionProfileViews(_ items: [DefaultInteractionProfile]) -> [DefaultInteractionProfileView] {
        var views: [DefaultInteractionProfileView] = []
        for item in items {
            views.append(toDefaultInteractionProfileView(item))
        }
        return views
    }

    static func sumDefaultInteractionProfileView(_ view: DefaultInteractionProfileView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedWindowDays) + parsedFloorValue + Double(parsedVersion)
    }
}
