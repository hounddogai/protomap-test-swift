import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive acuity plan window.
    final class AdaptiveAcuityPlanWindowView {
        var codeText: String
        var labelText: String
        var ward: String
        var durationMinutes: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, labelText: String, ward: String, durationMinutes: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAcuityPlanWindowView(_ item: AdaptiveAcuityPlanWindow) -> AdaptiveAcuityPlanWindowView {
        return AdaptiveAcuityPlanWindowView(
            codeText: item.code,
            labelText: item.label,
            ward: item.ward,
            durationMinutes: String(item.durationMinutes),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAcuityPlanWindowViews(_ items: [AdaptiveAcuityPlanWindow]) -> [AdaptiveAcuityPlanWindowView] {
        var views: [AdaptiveAcuityPlanWindowView] = []
        for item in items {
            views.append(toAdaptiveAcuityPlanWindowView(item))
        }
        return views
    }

    static func sumAdaptiveAcuityPlanWindowView(_ view: AdaptiveAcuityPlanWindowView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
