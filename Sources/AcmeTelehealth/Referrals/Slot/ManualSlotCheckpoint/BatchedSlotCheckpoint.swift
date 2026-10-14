import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot checkpoint is in its life cycle.
    enum BatchedSlotCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched slot checkpoint, with what the planners need to act on it.
    final class BatchedSlotCheckpoint {
        var code: String
        var name: String
        var ceiling: Double
        var threshold: Double
        var expiresAt: Int
        var summary: String
        var category: String
        var retries: Int
        var currency: String
        var status: BatchedSlotCheckpointStatus

        init(code: String, name: String, ceiling: Double, threshold: Double, expiresAt: Int, summary: String, category: String, retries: Int, currency: String, status: BatchedSlotCheckpointStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.threshold = threshold
            self.expiresAt = expiresAt
            self.summary = summary
            self.category = category
            self.retries = retries
            self.currency = currency
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

        func canMoveTo(_ next: BatchedSlotCheckpointStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedSlotCheckpointStatus.validated || next == BatchedSlotCheckpointStatus.published
            case .validated:
                return next == BatchedSlotCheckpointStatus.published || next == BatchedSlotCheckpointStatus.retired
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

        func moveTo(_ next: BatchedSlotCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return (Double(expiresAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> BatchedSlotCheckpoint {
            return BatchedSlotCheckpoint(
                code: code,
                name: name,
                ceiling: ceiling,
                threshold: threshold,
                expiresAt: expiresAt,
                summary: summary,
                category: category,
                retries: retries,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched slot checkpoint in status created.
    static func newBatchedSlotCheckpoint(_ code: String, name: String) -> BatchedSlotCheckpoint {
        return BatchedSlotCheckpoint(
            code: code,
            name: name,
            ceiling: 0.0,
            threshold: 0.0,
            expiresAt: 0,
            summary: "",
            category: "",
            retries: 0,
            currency: "",
            status: BatchedSlotCheckpointStatus.created
        )
    }
}
