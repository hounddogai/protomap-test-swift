import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program checkpoint is in its life cycle.
    enum ProgramCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a program checkpoint and its current status.
    final class ProgramCheckpoint {
        var code: String
        var name: String
        var ratio: Double
        var segment: String
        var title: String
        var status: ProgramCheckpointStatus

        init(code: String, name: String, ratio: Double, segment: String, title: String, status: ProgramCheckpointStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.segment = segment
            self.title = title
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

        func canMoveTo(_ next: ProgramCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == ProgramCheckpointStatus.scheduled || next == ProgramCheckpointStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ProgramCheckpointStatus.cancelled
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

        func moveTo(_ next: ProgramCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program checkpoint") \(code)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> ProgramCheckpoint {
            return ProgramCheckpoint(
                code: code,
                name: name,
                ratio: ratio,
                segment: segment,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a program checkpoint in status planned.
    static func newProgramCheckpoint(_ code: String, name: String) -> ProgramCheckpoint {
        return ProgramCheckpoint(
            code: code,
            name: name,
            ratio: 0.0,
            segment: "",
            title: "",
            status: ProgramCheckpointStatus.planned
        )
    }
}
