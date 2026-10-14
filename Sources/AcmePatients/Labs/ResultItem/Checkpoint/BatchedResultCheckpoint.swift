import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched result checkpoint is in its life cycle.
    enum BatchedResultCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched result checkpoint, with what the planners need to act on it.
    final class BatchedResultCheckpoint {
        var code: String
        var title: String
        var patientRef: String
        var batchSize: Int
        var country: String
        var graceDays: Int
        var status: BatchedResultCheckpointStatus

        init(code: String, title: String, patientRef: String, batchSize: Int, country: String, graceDays: Int, status: BatchedResultCheckpointStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.country = country
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedResultCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedResultCheckpointStatus.granted
            case .granted:
                return next == BatchedResultCheckpointStatus.expired
            case .revoked:
                return next == BatchedResultCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedResultCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched result checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched result checkpoint") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(graceDays) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedResultCheckpoint {
            return BatchedResultCheckpoint(
                code: code,
                title: title,
                patientRef: patientRef,
                batchSize: batchSize,
                country: country,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched result checkpoint in status requested.
    static func newBatchedResultCheckpoint(_ code: String, title: String) -> BatchedResultCheckpoint {
        return BatchedResultCheckpoint(
            code: code,
            title: title,
            patientRef: "",
            batchSize: 0,
            country: "",
            graceDays: 0,
            status: BatchedResultCheckpointStatus.requested
        )
    }
}
