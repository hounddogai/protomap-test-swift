import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime claim.
    final class OvertimeClaimView {
        var code: String
        var labelText: String
        var timezone: String
        var startsAt: String
        var locale: String
        var statusLabel: String

        init(code: String, labelText: String, timezone: String, startsAt: String, locale: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.timezone = timezone
            self.startsAt = startsAt
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeClaimView(_ item: OvertimeClaim) -> OvertimeClaimView {
        return OvertimeClaimView(
            code: item.code,
            labelText: item.label,
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            startsAt: String(item.startsAt),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeClaimViews(_ items: [OvertimeClaim]) -> [OvertimeClaimView] {
        var views: [OvertimeClaimView] = []
        for item in items {
            views.append(toOvertimeClaimView(item))
        }
        return views
    }

    static func sumOvertimeClaimView(_ view: OvertimeClaimView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
