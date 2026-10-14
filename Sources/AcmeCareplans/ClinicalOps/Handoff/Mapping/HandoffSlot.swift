import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff slot is in its life cycle.
    enum HandoffSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A handoff slot as the handoff team keeps it.
    final class HandoffSlot {
        var code: String
        var name: String
        var checksum: String
        var phone: String
        var pinned: Bool
        var archived: Bool
        var floorValue: Double
        var status: HandoffSlotStatus

        init(code: String, name: String, checksum: String, phone: String, pinned: Bool, archived: Bool, floorValue: Double, status: HandoffSlotStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.phone = phone
            self.pinned = pinned
            self.archived = archived
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffSlotStatus) -> Bool {
            switch status {
            case .planned:
                return next == HandoffSlotStatus.scheduled || next == HandoffSlotStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: HandoffSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("handoff slot") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> HandoffSlot {
            return HandoffSlot(
                code: code,
                name: name,
                checksum: checksum,
                phone: phone,
                pinned: pinned,
                archived: archived,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a handoff slot in status planned.
    static func newHandoffSlot(_ code: String, name: String) -> HandoffSlot {
        return HandoffSlot(
            code: code,
            name: name,
            checksum: "",
            phone: "",
            pinned: false,
            archived: false,
            floorValue: 0.0,
            status: HandoffSlotStatus.planned
        )
    }
}
