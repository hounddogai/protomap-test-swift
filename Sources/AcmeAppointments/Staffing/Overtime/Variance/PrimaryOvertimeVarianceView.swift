import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary overtime variance.
    final class PrimaryOvertimeVarianceView {
        var code: String
        var label: String
        var attempts: String
        var timezoneText: String
        var segment: String
        var copay: String
        var title: String
        var limit: String
        var endsAt: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, label: String, attempts: String, timezoneText: String, segment: String, copay: String, title: String, limit: String, endsAt: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.timezoneText = timezoneText
            self.segment = segment
            self.copay = copay
            self.title = title
            self.limit = limit
            self.endsAt = endsAt
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOvertimeVarianceView(_ item: PrimaryOvertimeVariance) -> PrimaryOvertimeVarianceView {
        return PrimaryOvertimeVarianceView(
            code: item.code,
            label: item.label,
            attempts: String(item.attempts),
            timezoneText: item.timezone,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            copay: String(format: "%.2f", item.copay),
            title: item.title,
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOvertimeVarianceViews(_ items: [PrimaryOvertimeVariance]) -> [PrimaryOvertimeVarianceView] {
        var views: [PrimaryOvertimeVarianceView] = []
        for item in items {
            views.append(toPrimaryOvertimeVarianceView(item))
        }
        return views
    }

    static func sumPrimaryOvertimeVarianceView(_ view: PrimaryOvertimeVarianceView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAttempts) + parsedCopay + Double(parsedLimit)
    }
}
