import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study batch is in its life cycle.
    enum TieredStudyBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a tiered study batch and its current status.
    final class TieredStudyBatch {
        var code: String
        var name: String
        var acuity: Int
        var budget: Double
        var updatedAt: Int
        var createdAt: Int
        var retries: Int
        var status: TieredStudyBatchStatus

        init(code: String, name: String, acuity: Int, budget: Double, updatedAt: Int, createdAt: Int, retries: Int, status: TieredStudyBatchStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.budget = budget
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.retries = retries
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

        func canMoveTo(_ next: TieredStudyBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredStudyBatchStatus.cancelled
            case .scheduled:
                return next == TieredStudyBatchStatus.cancelled
            case .inProgress:
                return next == TieredStudyBatchStatus.completed
            case .completed:
                return next == TieredStudyBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredStudyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(acuity) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredStudyBatch {
            return TieredStudyBatch(
                code: code,
                name: name,
                acuity: acuity,
                budget: budget,
                updatedAt: updatedAt,
                createdAt: createdAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered study batch in status planned.
    static func newTieredStudyBatch(_ code: String, name: String) -> TieredStudyBatch {
        return TieredStudyBatch(
            code: code,
            name: name,
            acuity: 0,
            budget: 0.0,
            updatedAt: 0,
            createdAt: 0,
            retries: 0,
            status: TieredStudyBatchStatus.planned
        )
    }
}
