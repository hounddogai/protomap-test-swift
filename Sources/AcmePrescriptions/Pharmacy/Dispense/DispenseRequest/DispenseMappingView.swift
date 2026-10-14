import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense mapping.
    final class DispenseMappingView {
        var code: String
        var name: String
        var threshold: String
        var durationMinutesText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, threshold: String, durationMinutesText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.durationMinutesText = durationMinutesText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseMappingView(_ item: DispenseMapping) -> DispenseMappingView {
        return DispenseMappingView(
            code: item.code,
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            durationMinutesText: String(item.durationMinutes),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseMappingViews(_ items: [DispenseMapping]) -> [DispenseMappingView] {
        var views: [DispenseMappingView] = []
        for item in items {
            views.append(toDispenseMappingView(item))
        }
        return views
    }

    static func sumDispenseMappingView(_ view: DispenseMappingView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes)
    }
}
