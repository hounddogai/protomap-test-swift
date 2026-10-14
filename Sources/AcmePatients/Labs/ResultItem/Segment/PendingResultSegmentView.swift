import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending result segment.
    final class PendingResultSegmentView {
        var code: String
        var title: String
        var ownerID: String
        var segment: String
        var priority: String
        var startsAt: String
        var diagnosisCode: String
        var revision: String
        var unitText: String
        var description: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, segment: String, priority: String, startsAt: String, diagnosisCode: String, revision: String, unitText: String, description: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.segment = segment
            self.priority = priority
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.unitText = unitText
            self.description = description
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingResultSegmentView(_ item: PendingResultSegment) -> PendingResultSegmentView {
        return PendingResultSegmentView(
            code: item.code,
            title: item.title,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            segment: item.segment,
            priority: String(item.priority),
            startsAt: String(item.startsAt),
            diagnosisCode: item.diagnosisCode,
            revision: String(item.revision),
            unitText: item.unit,
            description: Kit.Text.truncate(item.description, limit: 80),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingResultSegmentViews(_ items: [PendingResultSegment]) -> [PendingResultSegmentView] {
        var views: [PendingResultSegmentView] = []
        for item in items {
            views.append(toPendingResultSegmentView(item))
        }
        return views
    }

    static func sumPendingResultSegmentView(_ view: PendingResultSegmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedPriority) + Double(parsedStartsAt) + Double(parsedRevision)
    }
}
