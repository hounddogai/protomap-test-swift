import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling program baseline is in its life cycle.
    enum RollingProgramBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling program baseline as the program team keeps it.
    final class RollingProgramBaseline {
        var code: String
        var title: String
        var score: Double
        var capacity: Int
        var startsAt: Int
        var notes: String
        var archived: Bool
        var specialty: String
        var encounterID: String
        var active: Bool
        var status: RollingProgramBaselineStatus

        init(code: String, title: String, score: Double, capacity: Int, startsAt: Int, notes: String, archived: Bool, specialty: String, encounterID: String, active: Bool, status: RollingProgramBaselineStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.capacity = capacity
            self.startsAt = startsAt
            self.notes = notes
            self.archived = archived
            self.specialty = specialty
            self.encounterID = encounterID
            self.active = active
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

        func canMoveTo(_ next: RollingProgramBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RollingProgramBaselineStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingProgramBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling program baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return (score * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingProgramBaseline {
            return RollingProgramBaseline(
                code: code,
                title: title,
                score: score,
                capacity: capacity,
                startsAt: startsAt,
                notes: notes,
                archived: archived,
                specialty: specialty,
                encounterID: encounterID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling program baseline in status draft.
    static func newRollingProgramBaseline(_ code: String, title: String) -> RollingProgramBaseline {
        return RollingProgramBaseline(
            code: code,
            title: title,
            score: 0.0,
            capacity: 0,
            startsAt: 0,
            notes: "",
            archived: false,
            specialty: "",
            encounterID: "",
            active: false,
            status: RollingProgramBaselineStatus.draft
        )
    }
}
