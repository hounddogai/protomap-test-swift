import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled inventory slot is in its life cycle.
    enum ScheduledInventorySlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled inventory slot as the inventory team keeps it.
    final class ScheduledInventorySlot {
        var code: String
        var label: String
        var acuity: Int
        var minimum: Double
        var retries: Int
        var expiresAt: Int
        var startsAt: Int
        var patientRef: String
        var status: ScheduledInventorySlotStatus

        init(code: String, label: String, acuity: Int, minimum: Double, retries: Int, expiresAt: Int, startsAt: Int, patientRef: String, status: ScheduledInventorySlotStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.minimum = minimum
            self.retries = retries
            self.expiresAt = expiresAt
            self.startsAt = startsAt
            self.patientRef = patientRef
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

        func canMoveTo(_ next: ScheduledInventorySlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledInventorySlotStatus.draining
            case .ready:
                return next == ScheduledInventorySlotStatus.stopped
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

        func moveTo(_ next: ScheduledInventorySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled inventory slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled inventory slot") \(code)"
        }

        func projectedLoad() -> Double {
            return ((minimum + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledInventorySlot {
            return ScheduledInventorySlot(
                code: code,
                label: label,
                acuity: acuity,
                minimum: minimum,
                retries: retries,
                expiresAt: expiresAt,
                startsAt: startsAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled inventory slot in status idle.
    static func newScheduledInventorySlot(_ code: String, label: String) -> ScheduledInventorySlot {
        return ScheduledInventorySlot(
            code: code,
            label: label,
            acuity: 0,
            minimum: 0.0,
            retries: 0,
            expiresAt: 0,
            startsAt: 0,
            patientRef: "",
            status: ScheduledInventorySlotStatus.idle
        )
    }
}
