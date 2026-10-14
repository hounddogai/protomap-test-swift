import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory slot is in its life cycle.
    enum InventorySlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a inventory slot and its current status.
    final class InventorySlot {
        var code: String
        var title: String
        var clinicianID: String
        var channel: String
        var visible: Bool
        var quantity: Int
        var payer: String
        var status: InventorySlotStatus

        init(code: String, title: String, clinicianID: String, channel: String, visible: Bool, quantity: Int, payer: String, status: InventorySlotStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.channel = channel
            self.visible = visible
            self.quantity = quantity
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventorySlotStatus) -> Bool {
            switch status {
            case .idle:
                return next == InventorySlotStatus.draining
            case .warming:
                return next == InventorySlotStatus.draining
            case .ready:
                return next == InventorySlotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: InventorySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("inventory slot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> InventorySlot {
            return InventorySlot(
                code: code,
                title: title,
                clinicianID: clinicianID,
                channel: channel,
                visible: visible,
                quantity: quantity,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a inventory slot in status idle.
    static func newInventorySlot(_ code: String, title: String) -> InventorySlot {
        return InventorySlot(
            code: code,
            title: title,
            clinicianID: "",
            channel: "",
            visible: false,
            quantity: 0,
            payer: "",
            status: InventorySlotStatus.idle
        )
    }
}
