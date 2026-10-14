import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer digest is in its life cycle.
    enum TransferDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A transfer digest. Its code is unique within a tenant.
    final class TransferDigest {
        var code: String
        var label: String
        var reviewer: String
        var threshold: Double
        var ratio: Double
        var status: TransferDigestStatus

        init(code: String, label: String, reviewer: String, threshold: Double, ratio: Double, status: TransferDigestStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.threshold = threshold
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TransferDigestStatus.rejected || next == TransferDigestStatus.withdrawn
            case .approved:
                return next == TransferDigestStatus.rejected
            case .rejected:
                return next == TransferDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("transfer digest") \(code)"
        }

        func weightedTotal() -> Double {
            return (threshold * ratio * 100).rounded() / 100
        }

        func copyValue() -> TransferDigest {
            return TransferDigest(
                code: code,
                label: label,
                reviewer: reviewer,
                threshold: threshold,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer digest in status proposed.
    static func newTransferDigest(_ code: String, label: String) -> TransferDigest {
        return TransferDigest(
            code: code,
            label: label,
            reviewer: "",
            threshold: 0.0,
            ratio: 0.0,
            status: TransferDigestStatus.proposed
        )
    }
}
