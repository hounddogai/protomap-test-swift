import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched language target is in its life cycle.
    enum BatchedLanguageTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched language target. Its code is unique within a tenant.
    final class BatchedLanguageTarget {
        var code: String
        var label: String
        var channel: String
        var maximum: Double
        var updatedAt: Int
        var status: BatchedLanguageTargetStatus

        init(code: String, label: String, channel: String, maximum: Double, updatedAt: Int, status: BatchedLanguageTargetStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.maximum = maximum
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: BatchedLanguageTargetStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedLanguageTargetStatus.scheduled || next == BatchedLanguageTargetStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == BatchedLanguageTargetStatus.cancelled
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

        func moveTo(_ next: BatchedLanguageTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched language target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(updatedAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> BatchedLanguageTarget {
            return BatchedLanguageTarget(
                code: code,
                label: label,
                channel: channel,
                maximum: maximum,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched language target in status planned.
    static func newBatchedLanguageTarget(_ code: String, label: String) -> BatchedLanguageTarget {
        return BatchedLanguageTarget(
            code: code,
            label: label,
            channel: "",
            maximum: 0.0,
            updatedAt: 0,
            status: BatchedLanguageTargetStatus.planned
        )
    }
}
