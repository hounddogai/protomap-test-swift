import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary shift window is in its life cycle.
    enum PrimaryShiftWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary shift window as the shift team keeps it.
    final class PrimaryShiftWindow {
        var code: String
        var label: String
        var encounterID: String
        var attempts: Int
        var active: Bool
        var graceDays: Int
        var facility: String
        var floorValue: Double
        var summary: String
        var status: PrimaryShiftWindowStatus

        init(code: String, label: String, encounterID: String, attempts: Int, active: Bool, graceDays: Int, facility: String, floorValue: Double, summary: String, status: PrimaryShiftWindowStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.attempts = attempts
            self.active = active
            self.graceDays = graceDays
            self.facility = facility
            self.floorValue = floorValue
            self.summary = summary
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

        func canMoveTo(_ next: PrimaryShiftWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryShiftWindowStatus.validated || next == PrimaryShiftWindowStatus.published
            case .validated:
                return next == PrimaryShiftWindowStatus.published || next == PrimaryShiftWindowStatus.retired
            case .published:
                return next == PrimaryShiftWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryShiftWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary shift window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(attempts) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryShiftWindow {
            return PrimaryShiftWindow(
                code: code,
                label: label,
                encounterID: encounterID,
                attempts: attempts,
                active: active,
                graceDays: graceDays,
                facility: facility,
                floorValue: floorValue,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary shift window in status created.
    static func newPrimaryShiftWindow(_ code: String, label: String) -> PrimaryShiftWindow {
        return PrimaryShiftWindow(
            code: code,
            label: label,
            encounterID: "",
            attempts: 0,
            active: false,
            graceDays: 0,
            facility: "",
            floorValue: 0.0,
            summary: "",
            status: PrimaryShiftWindowStatus.created
        )
    }
}
