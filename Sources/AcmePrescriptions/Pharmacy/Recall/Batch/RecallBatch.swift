import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall batch is in its life cycle.
    enum RecallBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A recall batch. Its code is unique within a tenant.
    final class RecallBatch {
        var code: String
        var label: String
        var cost: Double
        var attempts: Int
        var visitMinutes: Int
        var version: Int
        var status: RecallBatchStatus

        init(code: String, label: String, cost: Double, attempts: Int, visitMinutes: Int, version: Int, status: RecallBatchStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.version = version
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

        func canMoveTo(_ next: RecallBatchStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
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
                case .completed:
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

        func moveTo(_ next: RecallBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return (Double(version) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RecallBatch {
            return RecallBatch(
                code: code,
                label: label,
                cost: cost,
                attempts: attempts,
                visitMinutes: visitMinutes,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a recall batch in status planned.
    static func newRecallBatch(_ code: String, label: String) -> RecallBatch {
        return RecallBatch(
            code: code,
            label: label,
            cost: 0.0,
            attempts: 0,
            visitMinutes: 0,
            version: 0,
            status: RecallBatchStatus.planned
        )
    }
}
