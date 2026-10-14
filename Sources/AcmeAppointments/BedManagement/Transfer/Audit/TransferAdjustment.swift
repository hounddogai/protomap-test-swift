import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer adjustment is in its life cycle.
    enum TransferAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a transfer adjustment and its current status.
    final class TransferAdjustment {
        var code: String
        var title: String
        var ceiling: Double
        var pinned: Bool
        var ratio: Double
        var graceDays: Int
        var version: Int
        var status: TransferAdjustmentStatus

        init(code: String, title: String, ceiling: Double, pinned: Bool, ratio: Double, graceDays: Int, version: Int, status: TransferAdjustmentStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.pinned = pinned
            self.ratio = ratio
            self.graceDays = graceDays
            self.version = version
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

        func canMoveTo(_ next: TransferAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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
                return next == TransferAdjustmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return (Double(graceDays) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> TransferAdjustment {
            return TransferAdjustment(
                code: code,
                title: title,
                ceiling: ceiling,
                pinned: pinned,
                ratio: ratio,
                graceDays: graceDays,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a transfer adjustment in status proposed.
    static func newTransferAdjustment(_ code: String, title: String) -> TransferAdjustment {
        return TransferAdjustment(
            code: code,
            title: title,
            ceiling: 0.0,
            pinned: false,
            ratio: 0.0,
            graceDays: 0,
            version: 0,
            status: TransferAdjustmentStatus.proposed
        )
    }
}
