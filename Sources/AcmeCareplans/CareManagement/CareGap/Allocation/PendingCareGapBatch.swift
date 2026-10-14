import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending care gap batch is in its life cycle.
    enum PendingCareGapBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending care gap batch, with what the planners need to act on it.
    final class PendingCareGapBatch {
        var code: String
        var label: String
        var summary: String
        var quantity: Int
        var expiresAt: Int
        var status: PendingCareGapBatchStatus

        init(code: String, label: String, summary: String, quantity: Int, expiresAt: Int, status: PendingCareGapBatchStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.quantity = quantity
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: PendingCareGapBatchStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingCareGapBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCareGapBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care gap batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(expiresAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCareGapBatch {
            return PendingCareGapBatch(
                code: code,
                label: label,
                summary: summary,
                quantity: quantity,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending care gap batch in status proposed.
    static func newPendingCareGapBatch(_ code: String, label: String) -> PendingCareGapBatch {
        return PendingCareGapBatch(
            code: code,
            label: label,
            summary: "",
            quantity: 0,
            expiresAt: 0,
            status: PendingCareGapBatchStatus.proposed
        )
    }
}
