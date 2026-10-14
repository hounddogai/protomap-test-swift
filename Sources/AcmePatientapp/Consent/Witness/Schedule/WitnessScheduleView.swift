import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness schedule.
    final class WitnessScheduleView {
        var codeText: String
        var title: String
        var updatedAtText: String
        var refills: String
        var bedText: String
        var pinned: String
        var localeText: String
        var statusLabel: String

        init(codeText: String, title: String, updatedAtText: String, refills: String, bedText: String, pinned: String, localeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.updatedAtText = updatedAtText
            self.refills = refills
            self.bedText = bedText
            self.pinned = pinned
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessScheduleView(_ item: WitnessSchedule) -> WitnessScheduleView {
        return WitnessScheduleView(
            codeText: item.code,
            title: item.title,
            updatedAtText: String(item.updatedAt),
            refills: String(item.refills),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            pinned: "\(item.pinned)",
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessScheduleViews(_ items: [WitnessSchedule]) -> [WitnessScheduleView] {
        var views: [WitnessScheduleView] = []
        for item in items {
            views.append(toWitnessScheduleView(item))
        }
        return views
    }

    static func sumWitnessScheduleView(_ view: WitnessScheduleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedRefills)
    }
}
