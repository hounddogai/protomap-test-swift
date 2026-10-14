import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority schedule.
    final class PriorityScheduleView {
        var code: String
        var labelText: String
        var sequenceText: String
        var graceDays: String
        var ownerID: String
        var statusLabel: String

        init(code: String, labelText: String, sequenceText: String, graceDays: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.sequenceText = sequenceText
            self.graceDays = graceDays
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityScheduleView(_ item: PrioritySchedule) -> PriorityScheduleView {
        return PriorityScheduleView(
            code: item.code,
            labelText: item.label,
            sequenceText: String(item.sequence),
            graceDays: String(item.graceDays),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityScheduleViews(_ items: [PrioritySchedule]) -> [PriorityScheduleView] {
        var views: [PriorityScheduleView] = []
        for item in items {
            views.append(toPriorityScheduleView(item))
        }
        return views
    }

    static func sumPriorityScheduleView(_ view: PriorityScheduleView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedSequence) + Double(parsedGraceDays)
    }
}
