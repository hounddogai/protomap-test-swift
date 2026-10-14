import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient reference range schedule.
    final class LenientReferenceRangeScheduleView {
        var codeText: String
        var title: String
        var endsAt: String
        var capacity: String
        var locale: String
        var visible: String
        var limit: String
        var sequence: String
        var notes: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, title: String, endsAt: String, capacity: String, locale: String, visible: String, limit: String, sequence: String, notes: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.endsAt = endsAt
            self.capacity = capacity
            self.locale = locale
            self.visible = visible
            self.limit = limit
            self.sequence = sequence
            self.notes = notes
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReferenceRangeScheduleView(_ item: LenientReferenceRangeSchedule) -> LenientReferenceRangeScheduleView {
        return LenientReferenceRangeScheduleView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            endsAt: String(item.endsAt),
            capacity: String(item.capacity),
            locale: item.locale,
            visible: "\(item.visible)",
            limit: String(item.limit),
            sequence: String(item.sequence),
            notes: item.notes,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReferenceRangeScheduleViews(_ items: [LenientReferenceRangeSchedule]) -> [LenientReferenceRangeScheduleView] {
        var views: [LenientReferenceRangeScheduleView] = []
        for item in items {
            views.append(toLenientReferenceRangeScheduleView(item))
        }
        return views
    }

    static func sumLenientReferenceRangeScheduleView(_ view: LenientReferenceRangeScheduleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCapacity) + Double(parsedLimit)
    }
}
