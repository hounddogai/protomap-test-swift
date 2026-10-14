import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary task exception is in its life cycle.
    enum PrimaryTaskExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary task exception. Its code is unique within a tenant.
    final class PrimaryTaskException {
        var code: String
        var label: String
        var active: Bool
        var copay: Double
        var sequence: Int
        var status: PrimaryTaskExceptionStatus

        init(code: String, label: String, active: Bool, copay: Double, sequence: Int, status: PrimaryTaskExceptionStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.copay = copay
            self.sequence = sequence
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

        func canMoveTo(_ next: PrimaryTaskExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryTaskExceptionStatus.draining || next == PrimaryTaskExceptionStatus.stopped
            case .warming:
                return next == PrimaryTaskExceptionStatus.draining || next == PrimaryTaskExceptionStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryTaskExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryTaskExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary task exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (copay * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryTaskException {
            return PrimaryTaskException(
                code: code,
                label: label,
                active: active,
                copay: copay,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary task exception in status idle.
    static func newPrimaryTaskException(_ code: String, label: String) -> PrimaryTaskException {
        return PrimaryTaskException(
            code: code,
            label: label,
            active: false,
            copay: 0.0,
            sequence: 0,
            status: PrimaryTaskExceptionStatus.idle
        )
    }
}
