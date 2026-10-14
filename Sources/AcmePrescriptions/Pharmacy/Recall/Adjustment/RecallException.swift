import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall exception is in its life cycle.
    enum RecallExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One recall exception, with what the planners need to act on it.
    final class RecallException {
        var code: String
        var name: String
        var revision: Int
        var sequence: Int
        var graceDays: Int
        var threshold: Double
        var updatedAt: Int
        var status: RecallExceptionStatus

        init(code: String, name: String, revision: Int, sequence: Int, graceDays: Int, threshold: Double, updatedAt: Int, status: RecallExceptionStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.sequence = sequence
            self.graceDays = graceDays
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallExceptionStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RecallExceptionStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("recall exception") \(code)"
        }

        func netExposure() -> Double {
            return ((threshold - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> RecallException {
            return RecallException(
                code: code,
                name: name,
                revision: revision,
                sequence: sequence,
                graceDays: graceDays,
                threshold: threshold,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall exception in status new.
    static func newRecallException(_ code: String, name: String) -> RecallException {
        return RecallException(
            code: code,
            name: name,
            revision: 0,
            sequence: 0,
            graceDays: 0,
            threshold: 0.0,
            updatedAt: 0,
            status: RecallExceptionStatus.new
        )
    }
}
