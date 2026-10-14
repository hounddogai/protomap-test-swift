import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled float pool assignment is in its life cycle.
    enum ScheduledFloatPoolAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled float pool assignment as the float pool team keeps it.
    final class ScheduledFloatPoolAssignment {
        var code: String
        var name: String
        var discount: Double
        var threshold: Double
        var durationMinutes: Int
        var status: ScheduledFloatPoolAssignmentStatus

        init(code: String, name: String, discount: Double, threshold: Double, durationMinutes: Int, status: ScheduledFloatPoolAssignmentStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledFloatPoolAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledFloatPoolAssignmentStatus.validated || next == ScheduledFloatPoolAssignmentStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ScheduledFloatPoolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled float pool assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return (threshold * discount * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFloatPoolAssignment {
            return ScheduledFloatPoolAssignment(
                code: code,
                name: name,
                discount: discount,
                threshold: threshold,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled float pool assignment in status created.
    static func newScheduledFloatPoolAssignment(_ code: String, name: String) -> ScheduledFloatPoolAssignment {
        return ScheduledFloatPoolAssignment(
            code: code,
            name: name,
            discount: 0.0,
            threshold: 0.0,
            durationMinutes: 0,
            status: ScheduledFloatPoolAssignmentStatus.created
        )
    }
}
