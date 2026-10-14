import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist request is in its life cycle.
    enum WorklistRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One worklist request, with what the planners need to act on it.
    final class WorklistRequest {
        var code: String
        var label: String
        var priority: Int
        var startsAt: Int
        var clinicianID: String
        var archived: Bool
        var weight: Double
        var sequence: Int
        var timezone: String
        var specialty: String
        var status: WorklistRequestStatus

        init(code: String, label: String, priority: Int, startsAt: Int, clinicianID: String, archived: Bool, weight: Double, sequence: Int, timezone: String, specialty: String, status: WorklistRequestStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.startsAt = startsAt
            self.clinicianID = clinicianID
            self.archived = archived
            self.weight = weight
            self.sequence = sequence
            self.timezone = timezone
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

        func canMoveTo(_ next: WorklistRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == WorklistRequestStatus.inProgress || next == WorklistRequestStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((Double(priority) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistRequest {
            return WorklistRequest(
                code: code,
                label: label,
                priority: priority,
                startsAt: startsAt,
                clinicianID: clinicianID,
                archived: archived,
                weight: weight,
                sequence: sequence,
                timezone: timezone,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist request in status planned.
    static func newWorklistRequest(_ code: String, label: String) -> WorklistRequest {
        return WorklistRequest(
            code: code,
            label: label,
            priority: 0,
            startsAt: 0,
            clinicianID: "",
            archived: false,
            weight: 0.0,
            sequence: 0,
            timezone: "",
            specialty: "",
            status: WorklistRequestStatus.planned
        )
    }
}
