import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program segment.
    final class ProgramSegmentView {
        var code: String
        var name: String
        var maximum: String
        var budget: String
        var timezone: String
        var bed: String
        var visitMinutes: String
        var revision: String
        var statusLabel: String

        init(code: String, name: String, maximum: String, budget: String, timezone: String, bed: String, visitMinutes: String, revision: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.budget = budget
            self.timezone = timezone
            self.bed = bed
            self.visitMinutes = visitMinutes
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toProgramSegmentView(_ item: ProgramSegment) -> ProgramSegmentView {
        return ProgramSegmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            budget: String(format: "%.2f", item.budget),
            timezone: item.timezone,
            bed: item.bed,
            visitMinutes: String(item.visitMinutes),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramSegmentViews(_ items: [ProgramSegment]) -> [ProgramSegmentView] {
        var views: [ProgramSegmentView] = []
        for item in items {
            views.append(toProgramSegmentView(item))
        }
        return views
    }

    static func sumProgramSegmentView(_ view: ProgramSegmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMaximum + parsedBudget + Double(parsedVisitMinutes)
    }
}
