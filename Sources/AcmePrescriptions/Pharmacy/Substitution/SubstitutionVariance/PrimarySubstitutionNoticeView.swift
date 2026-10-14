import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary substitution notice.
    final class PrimarySubstitutionNoticeView {
        var code: String
        var label: String
        var active: String
        var region: String
        var windowDays: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, active: String, region: String, windowDays: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.active = active
            self.region = region
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySubstitutionNoticeView(_ item: PrimarySubstitutionNotice) -> PrimarySubstitutionNoticeView {
        return PrimarySubstitutionNoticeView(
            code: item.code,
            label: item.label,
            active: "\(item.active)",
            region: item.region,
            windowDays: String(item.windowDays),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySubstitutionNoticeViews(_ items: [PrimarySubstitutionNotice]) -> [PrimarySubstitutionNoticeView] {
        var views: [PrimarySubstitutionNoticeView] = []
        for item in items {
            views.append(toPrimarySubstitutionNoticeView(item))
        }
        return views
    }

    static func sumPrimarySubstitutionNoticeView(_ view: PrimarySubstitutionNoticeView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedStartsAt)
    }
}
