import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer batch is in its life cycle.
    enum TransferBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One transfer batch, with what the planners need to act on it.
    final class TransferBatch {
        var code: String
        var title: String
        var pinned: Bool
        var segment: String
        var locale: String
        var quantity: Int
        var status: TransferBatchStatus

        init(code: String, title: String, pinned: Bool, segment: String, locale: String, quantity: Int, status: TransferBatchStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.segment = segment
            self.locale = locale
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TransferBatchStatus.resolved || next == TransferBatchStatus.reopened
            case .inReview:
                return next == TransferBatchStatus.reopened || next == TransferBatchStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == TransferBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer batch") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TransferBatch {
            return TransferBatch(
                code: code,
                title: title,
                pinned: pinned,
                segment: segment,
                locale: locale,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a transfer batch in status open.
    static func newTransferBatch(_ code: String, title: String) -> TransferBatch {
        return TransferBatch(
            code: code,
            title: title,
            pinned: false,
            segment: "",
            locale: "",
            quantity: 0,
            status: TransferBatchStatus.`open`
        )
    }
}
