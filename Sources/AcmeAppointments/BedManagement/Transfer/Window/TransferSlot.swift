import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer slot is in its life cycle.
    enum TransferSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A transfer slot as the transfer team keeps it.
    final class TransferSlot {
        var code: String
        var title: String
        var bed: String
        var payer: String
        var graceDays: Int
        var quantity: Int
        var minimum: Double
        var ownerID: String
        var refills: Int
        var status: TransferSlotStatus

        init(code: String, title: String, bed: String, payer: String, graceDays: Int, quantity: Int, minimum: Double, ownerID: String, refills: Int, status: TransferSlotStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.payer = payer
            self.graceDays = graceDays
            self.quantity = quantity
            self.minimum = minimum
            self.ownerID = ownerID
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferSlotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TransferSlotStatus.active || next == TransferSlotStatus.closed
            case .active:
                return next == TransferSlotStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TransferSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(refills) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TransferSlot {
            return TransferSlot(
                code: code,
                title: title,
                bed: bed,
                payer: payer,
                graceDays: graceDays,
                quantity: quantity,
                minimum: minimum,
                ownerID: ownerID,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a transfer slot in status draft.
    static func newTransferSlot(_ code: String, title: String) -> TransferSlot {
        return TransferSlot(
            code: code,
            title: title,
            bed: "",
            payer: "",
            graceDays: 0,
            quantity: 0,
            minimum: 0.0,
            ownerID: "",
            refills: 0,
            status: TransferSlotStatus.draft
        )
    }
}
