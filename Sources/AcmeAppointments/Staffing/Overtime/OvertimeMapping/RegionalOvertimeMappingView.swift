import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional overtime mapping.
    final class RegionalOvertimeMappingView {
        var code: String
        var nameText: String
        var procedureCodeText: String
        var copay: String
        var clinicianID: String
        var specialty: String
        var channel: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, nameText: String, procedureCodeText: String, copay: String, clinicianID: String, specialty: String, channel: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.procedureCodeText = procedureCodeText
            self.copay = copay
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.channel = channel
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOvertimeMappingView(_ item: RegionalOvertimeMapping) -> RegionalOvertimeMappingView {
        return RegionalOvertimeMappingView(
            code: item.code,
            nameText: item.name,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 64),
            copay: String(format: "%.2f", item.copay),
            clinicianID: item.clinicianID,
            specialty: item.specialty,
            channel: item.channel,
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOvertimeMappingViews(_ items: [RegionalOvertimeMapping]) -> [RegionalOvertimeMappingView] {
        var views: [RegionalOvertimeMappingView] = []
        for item in items {
            views.append(toRegionalOvertimeMappingView(item))
        }
        return views
    }

    static func sumRegionalOvertimeMappingView(_ view: RegionalOvertimeMappingView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
