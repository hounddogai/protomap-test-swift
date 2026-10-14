import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist request.
    final class WorklistRequestView {
        var code: String
        var labelText: String
        var priorityText: String
        var startsAt: String
        var clinicianIDText: String
        var archived: String
        var weight: String
        var sequence: String
        var timezone: String
        var specialty: String
        var statusLabel: String

        init(code: String, labelText: String, priorityText: String, startsAt: String, clinicianIDText: String, archived: String, weight: String, sequence: String, timezone: String, specialty: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priorityText = priorityText
            self.startsAt = startsAt
            self.clinicianIDText = clinicianIDText
            self.archived = archived
            self.weight = weight
            self.sequence = sequence
            self.timezone = timezone
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistRequestView(_ item: WorklistRequest) -> WorklistRequestView {
        return WorklistRequestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            priorityText: String(item.priority),
            startsAt: String(item.startsAt),
            clinicianIDText: item.clinicianID,
            archived: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            sequence: String(item.sequence),
            timezone: item.timezone,
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistRequestViews(_ items: [WorklistRequest]) -> [WorklistRequestView] {
        var views: [WorklistRequestView] = []
        for item in items {
            views.append(toWorklistRequestView(item))
        }
        return views
    }

    static func sumWorklistRequestView(_ view: WorklistRequestView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedPriority) + Double(parsedStartsAt) + parsedWeight
    }
}
