import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched cleaning record is in its life cycle.
    enum BatchedCleaningRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched cleaning record, with what the planners need to act on it.
    final class BatchedCleaningRecord {
        var code: String
        var label: String
        var payer: String
        var threshold: Double
        var budget: Double
        var createdAt: Int
        var sequence: Int
        var status: BatchedCleaningRecordStatus

        init(code: String, label: String, payer: String, threshold: Double, budget: Double, createdAt: Int, sequence: Int, status: BatchedCleaningRecordStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.threshold = threshold
            self.budget = budget
            self.createdAt = createdAt
            self.sequence = sequence
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

        func canMoveTo(_ next: BatchedCleaningRecordStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
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
                return next == BatchedCleaningRecordStatus.completed || next == BatchedCleaningRecordStatus.cancelled
            case .completed:
                return next == BatchedCleaningRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCleaningRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched cleaning record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(sequence) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCleaningRecord {
            return BatchedCleaningRecord(
                code: code,
                label: label,
                payer: payer,
                threshold: threshold,
                budget: budget,
                createdAt: createdAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched cleaning record in status planned.
    static func newBatchedCleaningRecord(_ code: String, label: String) -> BatchedCleaningRecord {
        return BatchedCleaningRecord(
            code: code,
            label: label,
            payer: "",
            threshold: 0.0,
            budget: 0.0,
            createdAt: 0,
            sequence: 0,
            status: BatchedCleaningRecordStatus.planned
        )
    }
}
