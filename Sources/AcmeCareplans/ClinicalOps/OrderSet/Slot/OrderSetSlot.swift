import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set slot is in its life cycle.
    enum OrderSetSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One order set slot, with what the planners need to act on it.
    final class OrderSetSlot {
        var code: String
        var title: String
        var priority: Int
        var bed: String
        var refills: Int
        var checksum: String
        var contactEmail: String
        var pinned: Bool
        var ratio: Double
        var visible: Bool
        var status: OrderSetSlotStatus

        init(code: String, title: String, priority: Int, bed: String, refills: Int, checksum: String, contactEmail: String, pinned: Bool, ratio: Double, visible: Bool, status: OrderSetSlotStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.bed = bed
            self.refills = refills
            self.checksum = checksum
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.ratio = ratio
            self.visible = visible
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

        func canMoveTo(_ next: OrderSetSlotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
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
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OrderSetSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return (ratio * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetSlot {
            return OrderSetSlot(
                code: code,
                title: title,
                priority: priority,
                bed: bed,
                refills: refills,
                checksum: checksum,
                contactEmail: contactEmail,
                pinned: pinned,
                ratio: ratio,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set slot in status proposed.
    static func newOrderSetSlot(_ code: String, title: String) -> OrderSetSlot {
        return OrderSetSlot(
            code: code,
            title: title,
            priority: 0,
            bed: "",
            refills: 0,
            checksum: "",
            contactEmail: "",
            pinned: false,
            ratio: 0.0,
            visible: false,
            status: OrderSetSlotStatus.proposed
        )
    }
}
