import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession profile.
    final class AccessionProfileView {
        var code: String
        var label: String
        var durationMinutes: String
        var weight: String
        var copay: String
        var statusLabel: String

        init(code: String, label: String, durationMinutes: String, weight: String, copay: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionProfileView(_ item: AccessionProfile) -> AccessionProfileView {
        return AccessionProfileView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            durationMinutes: String(item.durationMinutes),
            weight: String(format: "%.2f", item.weight),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionProfileViews(_ items: [AccessionProfile]) -> [AccessionProfileView] {
        var views: [AccessionProfileView] = []
        for item in items {
            views.append(toAccessionProfileView(item))
        }
        return views
    }

    static func sumAccessionProfileView(_ view: AccessionProfileView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedDurationMinutes) + parsedWeight + parsedCopay
    }
}
