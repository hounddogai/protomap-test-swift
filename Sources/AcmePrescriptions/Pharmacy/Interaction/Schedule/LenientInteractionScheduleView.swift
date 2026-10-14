import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient interaction schedule.
    final class LenientInteractionScheduleView {
        var codeText: String
        var title: String
        var copay: String
        var windowDays: String
        var visitMinutes: String
        var sourceText: String
        var ownerIDText: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, title: String, copay: String, windowDays: String, visitMinutes: String, sourceText: String, ownerIDText: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.copay = copay
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.sourceText = sourceText
            self.ownerIDText = ownerIDText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInteractionScheduleView(_ item: LenientInteractionSchedule) -> LenientInteractionScheduleView {
        return LenientInteractionScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            windowDays: String(item.windowDays),
            visitMinutes: String(item.visitMinutes),
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInteractionScheduleViews(_ items: [LenientInteractionSchedule]) -> [LenientInteractionScheduleView] {
        var views: [LenientInteractionScheduleView] = []
        for item in items {
            views.append(toLenientInteractionScheduleView(item))
        }
        return views
    }

    static func sumLenientInteractionScheduleView(_ view: LenientInteractionScheduleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedCopay + Double(parsedWindowDays) + Double(parsedVisitMinutes)
    }
}
