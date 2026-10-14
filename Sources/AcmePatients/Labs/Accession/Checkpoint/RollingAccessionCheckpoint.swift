import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession checkpoint is in its life cycle.
    enum RollingAccessionCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling accession checkpoint. Its code is unique within a tenant.
    final class RollingAccessionCheckpoint {
        var code: String
        var title: String
        var visible: Bool
        var timezone: String
        var startsAt: Int
        var specialty: String
        var status: RollingAccessionCheckpointStatus

        init(code: String, title: String, visible: Bool, timezone: String, startsAt: Int, specialty: String, status: RollingAccessionCheckpointStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.timezone = timezone
            self.startsAt = startsAt
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingAccessionCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingAccessionCheckpointStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RollingAccessionCheckpointStatus.closed
            case .suspended:
                return next == RollingAccessionCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAccessionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> RollingAccessionCheckpoint {
            return RollingAccessionCheckpoint(
                code: code,
                title: title,
                visible: visible,
                timezone: timezone,
                startsAt: startsAt,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling accession checkpoint in status draft.
    static func newRollingAccessionCheckpoint(_ code: String, title: String) -> RollingAccessionCheckpoint {
        return RollingAccessionCheckpoint(
            code: code,
            title: title,
            visible: false,
            timezone: "",
            startsAt: 0,
            specialty: "",
            status: RollingAccessionCheckpointStatus.draft
        )
    }
}
