import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer window is in its life cycle.
    enum TransferWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A transfer window as the transfer team keeps it.
    final class TransferWindow {
        var code: String
        var title: String
        var threshold: Double
        var externalRef: String
        var limit: Int
        var priority: Int
        var payer: String
        var status: TransferWindowStatus

        init(code: String, title: String, threshold: Double, externalRef: String, limit: Int, priority: Int, payer: String, status: TransferWindowStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.externalRef = externalRef
            self.limit = limit
            self.priority = priority
            self.payer = payer
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

        func canMoveTo(_ next: TransferWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == TransferWindowStatus.validated || next == TransferWindowStatus.retired
            case .validated:
                return next == TransferWindowStatus.published || next == TransferWindowStatus.retired
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

        func moveTo(_ next: TransferWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer window") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(priority) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> TransferWindow {
            return TransferWindow(
                code: code,
                title: title,
                threshold: threshold,
                externalRef: externalRef,
                limit: limit,
                priority: priority,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a transfer window in status created.
    static func newTransferWindow(_ code: String, title: String) -> TransferWindow {
        return TransferWindow(
            code: code,
            title: title,
            threshold: 0.0,
            externalRef: "",
            limit: 0,
            priority: 0,
            payer: "",
            status: TransferWindowStatus.created
        )
    }
}
