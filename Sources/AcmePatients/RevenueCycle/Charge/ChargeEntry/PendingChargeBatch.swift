import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending charge batch is in its life cycle.
    enum PendingChargeBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a pending charge batch and its current status.
    final class PendingChargeBatch {
        var code: String
        var title: String
        var discount: Double
        var summary: String
        var pinned: Bool
        var status: PendingChargeBatchStatus

        init(code: String, title: String, discount: Double, summary: String, pinned: Bool, status: PendingChargeBatchStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.summary = summary
            self.pinned = pinned
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

        func canMoveTo(_ next: PendingChargeBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingChargeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending charge batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> PendingChargeBatch {
            return PendingChargeBatch(
                code: code,
                title: title,
                discount: discount,
                summary: summary,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending charge batch in status requested.
    static func newPendingChargeBatch(_ code: String, title: String) -> PendingChargeBatch {
        return PendingChargeBatch(
            code: code,
            title: title,
            discount: 0.0,
            summary: "",
            pinned: false,
            status: PendingChargeBatchStatus.requested
        )
    }
}
