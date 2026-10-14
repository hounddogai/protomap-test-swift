import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched cleaning digest is in its life cycle.
    enum BatchedCleaningDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched cleaning digest as the cleaning team keeps it.
    final class BatchedCleaningDigest {
        var code: String
        var label: String
        var limit: Int
        var discount: Double
        var durationMinutes: Int
        var status: BatchedCleaningDigestStatus

        init(code: String, label: String, limit: Int, discount: Double, durationMinutes: Int, status: BatchedCleaningDigestStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.discount = discount
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: BatchedCleaningDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedCleaningDigestStatus.revoked || next == BatchedCleaningDigestStatus.expired
            case .granted:
                return next == BatchedCleaningDigestStatus.expired
            case .revoked:
                return next == BatchedCleaningDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCleaningDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched cleaning digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((discount + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCleaningDigest {
            return BatchedCleaningDigest(
                code: code,
                label: label,
                limit: limit,
                discount: discount,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched cleaning digest in status requested.
    static func newBatchedCleaningDigest(_ code: String, label: String) -> BatchedCleaningDigest {
        return BatchedCleaningDigest(
            code: code,
            label: label,
            limit: 0,
            discount: 0.0,
            durationMinutes: 0,
            status: BatchedCleaningDigestStatus.requested
        )
    }
}
