import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched task plan is in its life cycle.
    enum BatchedTaskPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched task plan, with what the planners need to act on it.
    final class BatchedTaskPlan {
        var code: String
        var label: String
        var ratio: Double
        var weight: Double
        var patientRef: String
        var status: BatchedTaskPlanStatus

        init(code: String, label: String, ratio: Double, weight: Double, patientRef: String, status: BatchedTaskPlanStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.weight = weight
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedTaskPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BatchedTaskPlanStatus.draining
            case .draining:
                return next == BatchedTaskPlanStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedTaskPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched task plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((ratio - weight) * 100).rounded() / 100
        }

        func copyValue() -> BatchedTaskPlan {
            return BatchedTaskPlan(
                code: code,
                label: label,
                ratio: ratio,
                weight: weight,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched task plan in status idle.
    static func newBatchedTaskPlan(_ code: String, label: String) -> BatchedTaskPlan {
        return BatchedTaskPlan(
            code: code,
            label: label,
            ratio: 0.0,
            weight: 0.0,
            patientRef: "",
            status: BatchedTaskPlanStatus.idle
        )
    }
}
