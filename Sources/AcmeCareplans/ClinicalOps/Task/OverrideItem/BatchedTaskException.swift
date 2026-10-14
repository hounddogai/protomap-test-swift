import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched task exception is in its life cycle.
    enum BatchedTaskExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched task exception as the task team keeps it.
    final class BatchedTaskException {
        var code: String
        var label: String
        var graceDays: Int
        var segment: String
        var weight: Double
        var limit: Int
        var acuity: Int
        var status: BatchedTaskExceptionStatus

        init(code: String, label: String, graceDays: Int, segment: String, weight: Double, limit: Int, acuity: Int, status: BatchedTaskExceptionStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.segment = segment
            self.weight = weight
            self.limit = limit
            self.acuity = acuity
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

        func canMoveTo(_ next: BatchedTaskExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedTaskExceptionStatus.ready || next == BatchedTaskExceptionStatus.stopped
            case .ready:
                return next == BatchedTaskExceptionStatus.draining || next == BatchedTaskExceptionStatus.stopped
            case .draining:
                return next == BatchedTaskExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedTaskExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched task exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return ((weight - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedTaskException {
            return BatchedTaskException(
                code: code,
                label: label,
                graceDays: graceDays,
                segment: segment,
                weight: weight,
                limit: limit,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched task exception in status idle.
    static func newBatchedTaskException(_ code: String, label: String) -> BatchedTaskException {
        return BatchedTaskException(
            code: code,
            label: label,
            graceDays: 0,
            segment: "",
            weight: 0.0,
            limit: 0,
            acuity: 0,
            status: BatchedTaskExceptionStatus.idle
        )
    }
}
