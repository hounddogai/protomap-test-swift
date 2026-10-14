import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling accession checkpoint.
    final class RollingAccessionCheckpointView {
        var code: String
        var title: String
        var visible: String
        var timezone: String
        var startsAt: String
        var specialty: String
        var statusLabel: String

        init(code: String, title: String, visible: String, timezone: String, startsAt: String, specialty: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visible = visible
            self.timezone = timezone
            self.startsAt = startsAt
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAccessionCheckpointView(_ item: RollingAccessionCheckpoint) -> RollingAccessionCheckpointView {
        return RollingAccessionCheckpointView(
            code: item.code,
            title: item.title,
            visible: "\(item.visible)",
            timezone: item.timezone,
            startsAt: String(item.startsAt),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAccessionCheckpointViews(_ items: [RollingAccessionCheckpoint]) -> [RollingAccessionCheckpointView] {
        var views: [RollingAccessionCheckpointView] = []
        for item in items {
            views.append(toRollingAccessionCheckpointView(item))
        }
        return views
    }

    static func sumRollingAccessionCheckpointView(_ view: RollingAccessionCheckpointView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
