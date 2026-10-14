import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling cleaning slot is in its life cycle.
    enum RollingCleaningSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rolling cleaning slot and its current status.
    final class RollingCleaningSlot {
        var code: String
        var title: String
        var summary: String
        var specialty: String
        var ceiling: Double
        var facility: String
        var pinned: Bool
        var status: RollingCleaningSlotStatus

        init(code: String, title: String, summary: String, specialty: String, ceiling: Double, facility: String, pinned: Bool, status: RollingCleaningSlotStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.specialty = specialty
            self.ceiling = ceiling
            self.facility = facility
            self.pinned = pinned
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

        func canMoveTo(_ next: RollingCleaningSlotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingCleaningSlotStatus.approved || next == RollingCleaningSlotStatus.rejected
            case .approved:
                return next == RollingCleaningSlotStatus.rejected || next == RollingCleaningSlotStatus.withdrawn
            case .rejected:
                return next == RollingCleaningSlotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCleaningSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling cleaning slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> RollingCleaningSlot {
            return RollingCleaningSlot(
                code: code,
                title: title,
                summary: summary,
                specialty: specialty,
                ceiling: ceiling,
                facility: facility,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling cleaning slot in status proposed.
    static func newRollingCleaningSlot(_ code: String, title: String) -> RollingCleaningSlot {
        return RollingCleaningSlot(
            code: code,
            title: title,
            summary: "",
            specialty: "",
            ceiling: 0.0,
            facility: "",
            pinned: false,
            status: RollingCleaningSlotStatus.proposed
        )
    }
}
