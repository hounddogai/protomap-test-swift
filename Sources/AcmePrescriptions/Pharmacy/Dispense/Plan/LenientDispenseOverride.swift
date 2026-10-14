import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient dispense override is in its life cycle.
    enum LenientDispenseOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient dispense override and its current status.
    final class LenientDispenseOverride {
        var code: String
        var title: String
        var durationMinutes: Int
        var patientRef: String
        var windowDays: Int
        var budget: Double
        var status: LenientDispenseOverrideStatus

        init(code: String, title: String, durationMinutes: Int, patientRef: String, windowDays: Int, budget: Double, status: LenientDispenseOverrideStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.budget = budget
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

        func canMoveTo(_ next: LenientDispenseOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientDispenseOverrideStatus.suspended
            case .pending:
                return next == LenientDispenseOverrideStatus.active || next == LenientDispenseOverrideStatus.closed
            case .active:
                return next == LenientDispenseOverrideStatus.suspended || next == LenientDispenseOverrideStatus.closed
            case .suspended:
                return next == LenientDispenseOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDispenseOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient dispense override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return ((budget + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientDispenseOverride {
            return LenientDispenseOverride(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                patientRef: patientRef,
                windowDays: windowDays,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient dispense override in status draft.
    static func newLenientDispenseOverride(_ code: String, title: String) -> LenientDispenseOverride {
        return LenientDispenseOverride(
            code: code,
            title: title,
            durationMinutes: 0,
            patientRef: "",
            windowDays: 0,
            budget: 0.0,
            status: LenientDispenseOverrideStatus.draft
        )
    }
}
