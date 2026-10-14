import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched isolation record is in its life cycle.
    enum BatchedIsolationRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched isolation record as the isolation team keeps it.
    final class BatchedIsolationRecord {
        var code: String
        var label: String
        var attempts: Int
        var batchSize: Int
        var sequence: Int
        var ownerID: String
        var copay: Double
        var pinned: Bool
        var description: String
        var status: BatchedIsolationRecordStatus

        init(code: String, label: String, attempts: Int, batchSize: Int, sequence: Int, ownerID: String, copay: Double, pinned: Bool, description: String, status: BatchedIsolationRecordStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.batchSize = batchSize
            self.sequence = sequence
            self.ownerID = ownerID
            self.copay = copay
            self.pinned = pinned
            self.description = description
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

        func canMoveTo(_ next: BatchedIsolationRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedIsolationRecordStatus.scheduled
            case .scheduled:
                return next == BatchedIsolationRecordStatus.inProgress
            case .inProgress:
                return next == BatchedIsolationRecordStatus.completed || next == BatchedIsolationRecordStatus.cancelled
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

        func moveTo(_ next: BatchedIsolationRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched isolation record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return (Double(attempts) * copay * 100).rounded() / 100
        }

        func copyValue() -> BatchedIsolationRecord {
            return BatchedIsolationRecord(
                code: code,
                label: label,
                attempts: attempts,
                batchSize: batchSize,
                sequence: sequence,
                ownerID: ownerID,
                copay: copay,
                pinned: pinned,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched isolation record in status planned.
    static func newBatchedIsolationRecord(_ code: String, label: String) -> BatchedIsolationRecord {
        return BatchedIsolationRecord(
            code: code,
            label: label,
            attempts: 0,
            batchSize: 0,
            sequence: 0,
            ownerID: "",
            copay: 0.0,
            pinned: false,
            description: "",
            status: BatchedIsolationRecordStatus.planned
        )
    }
}
