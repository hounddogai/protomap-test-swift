import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global program preference.
    final class GlobalProgramPreferenceView {
        var code: String
        var titleText: String
        var country: String
        var capacity: String
        var rateText: String
        var minimumText: String
        var externalRef: String
        var unit: String
        var statusLabel: String

        init(code: String, titleText: String, country: String, capacity: String, rateText: String, minimumText: String, externalRef: String, unit: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.country = country
            self.capacity = capacity
            self.rateText = rateText
            self.minimumText = minimumText
            self.externalRef = externalRef
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalProgramPreferenceView(_ item: GlobalProgramPreference) -> GlobalProgramPreferenceView {
        return GlobalProgramPreferenceView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            country: Kit.Text.truncate(item.country, limit: 64),
            capacity: String(item.capacity),
            rateText: String(format: "%.2f", item.rate),
            minimumText: String(format: "%.2f", item.minimum),
            externalRef: item.externalRef,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalProgramPreferenceViews(_ items: [GlobalProgramPreference]) -> [GlobalProgramPreferenceView] {
        var views: [GlobalProgramPreferenceView] = []
        for item in items {
            views.append(toGlobalProgramPreferenceView(item))
        }
        return views
    }

    static func sumGlobalProgramPreferenceView(_ view: GlobalProgramPreferenceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCapacity) + parsedRate + parsedMinimum
    }
}
