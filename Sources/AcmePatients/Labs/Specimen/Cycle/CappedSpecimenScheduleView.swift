import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped specimen schedule.
    final class CappedSpecimenScheduleView {
        var code: String
        var name: String
        var visitMinutes: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, visitMinutes: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSpecimenScheduleView(_ item: CappedSpecimenSchedule) -> CappedSpecimenScheduleView {
        return CappedSpecimenScheduleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            visitMinutes: String(item.visitMinutes),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSpecimenScheduleViews(_ items: [CappedSpecimenSchedule]) -> [CappedSpecimenScheduleView] {
        var views: [CappedSpecimenScheduleView] = []
        for item in items {
            views.append(toCappedSpecimenScheduleView(item))
        }
        return views
    }

    static func sumCappedSpecimenScheduleView(_ view: CappedSpecimenScheduleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
