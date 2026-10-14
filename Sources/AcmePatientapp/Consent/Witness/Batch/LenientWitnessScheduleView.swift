import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient witness schedule.
    final class LenientWitnessScheduleView {
        var code: String
        var title: String
        var revision: String
        var startsAtText: String
        var rate: String
        var allergy: String
        var acuity: String
        var statusLabel: String

        init(code: String, title: String, revision: String, startsAtText: String, rate: String, allergy: String, acuity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.startsAtText = startsAtText
            self.rate = rate
            self.allergy = allergy
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toLenientWitnessScheduleView(_ item: LenientWitnessSchedule) -> LenientWitnessScheduleView {
        return LenientWitnessScheduleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            revision: String(item.revision),
            startsAtText: String(item.startsAt),
            rate: String(format: "%.2f", item.rate),
            allergy: item.allergy,
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientWitnessScheduleViews(_ items: [LenientWitnessSchedule]) -> [LenientWitnessScheduleView] {
        var views: [LenientWitnessScheduleView] = []
        for item in items {
            views.append(toLenientWitnessScheduleView(item))
        }
        return views
    }

    static func sumLenientWitnessScheduleView(_ view: LenientWitnessScheduleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRevision) + Double(parsedStartsAt) + parsedRate
    }
}
