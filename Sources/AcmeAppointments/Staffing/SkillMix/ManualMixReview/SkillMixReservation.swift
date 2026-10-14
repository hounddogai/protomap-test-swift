import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix reservation is in its life cycle.
    enum SkillMixReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One skill mix reservation, with what the planners need to act on it.
    final class SkillMixReservation {
        var code: String
        var label: String
        var summary: String
        var updatedAt: Int
        var title: String
        var source: String
        var specialty: String
        var status: SkillMixReservationStatus

        init(code: String, label: String, summary: String, updatedAt: Int, title: String, source: String, specialty: String, status: SkillMixReservationStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.updatedAt = updatedAt
            self.title = title
            self.source = source
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SkillMixReservationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("skill mix reservation") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> SkillMixReservation {
            return SkillMixReservation(
                code: code,
                label: label,
                summary: summary,
                updatedAt: updatedAt,
                title: title,
                source: source,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a skill mix reservation in status planned.
    static func newSkillMixReservation(_ code: String, label: String) -> SkillMixReservation {
        return SkillMixReservation(
            code: code,
            label: label,
            summary: "",
            updatedAt: 0,
            title: "",
            source: "",
            specialty: "",
            status: SkillMixReservationStatus.planned
        )
    }
}
