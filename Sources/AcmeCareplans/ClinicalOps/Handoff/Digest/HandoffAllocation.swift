import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff allocation is in its life cycle.
    enum HandoffAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One handoff allocation, with what the planners need to act on it.
    final class HandoffAllocation {
        var code: String
        var title: String
        var label: String
        var copay: Double
        var attempts: Int
        var visitMinutes: Int
        var maximum: Double
        var status: HandoffAllocationStatus

        init(code: String, title: String, label: String, copay: Double, attempts: Int, visitMinutes: Int, maximum: Double, status: HandoffAllocationStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.copay = copay
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.maximum = maximum
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

        func canMoveTo(_ next: HandoffAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == HandoffAllocationStatus.completed || next == HandoffAllocationStatus.cancelled
            case .completed:
                return next == HandoffAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("handoff allocation") \(code)"
        }

        func netLoad() -> Double {
            return (copay * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> HandoffAllocation {
            return HandoffAllocation(
                code: code,
                title: title,
                label: label,
                copay: copay,
                attempts: attempts,
                visitMinutes: visitMinutes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff allocation in status planned.
    static func newHandoffAllocation(_ code: String, title: String) -> HandoffAllocation {
        return HandoffAllocation(
            code: code,
            title: title,
            label: "",
            copay: 0.0,
            attempts: 0,
            visitMinutes: 0,
            maximum: 0.0,
            status: HandoffAllocationStatus.planned
        )
    }
}
