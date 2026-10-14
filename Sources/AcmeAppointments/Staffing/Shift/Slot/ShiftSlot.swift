import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift slot is in its life cycle.
    enum ShiftSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A shift slot as the shift team keeps it.
    final class ShiftSlot {
        var code: String
        var name: String
        var diagnosisCode: String
        var title: String
        var active: Bool
        var capacity: Int
        var graceDays: Int
        var visible: Bool
        var refills: Int
        var status: ShiftSlotStatus

        init(code: String, name: String, diagnosisCode: String, title: String, active: Bool, capacity: Int, graceDays: Int, visible: Bool, refills: Int, status: ShiftSlotStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.active = active
            self.capacity = capacity
            self.graceDays = graceDays
            self.visible = visible
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == ShiftSlotStatus.running
            case .queued:
                return next == ShiftSlotStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ShiftSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(capacity) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftSlot {
            return ShiftSlot(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                title: title,
                active: active,
                capacity: capacity,
                graceDays: graceDays,
                visible: visible,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift slot in status new.
    static func newShiftSlot(_ code: String, name: String) -> ShiftSlot {
        return ShiftSlot(
            code: code,
            name: name,
            diagnosisCode: "",
            title: "",
            active: false,
            capacity: 0,
            graceDays: 0,
            visible: false,
            refills: 0,
            status: ShiftSlotStatus.new
        )
    }
}
