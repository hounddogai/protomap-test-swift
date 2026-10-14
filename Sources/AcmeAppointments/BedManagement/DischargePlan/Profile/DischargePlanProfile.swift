import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan profile is in its life cycle.
    enum DischargePlanProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A discharge plan profile as the discharge plan team keeps it.
    final class DischargePlanProfile {
        var code: String
        var title: String
        var attempts: Int
        var budget: Double
        var label: String
        var status: DischargePlanProfileStatus

        init(code: String, title: String, attempts: Int, budget: Double, label: String, status: DischargePlanProfileStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.budget = budget
            self.label = label
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

        func canMoveTo(_ next: DischargePlanProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == DischargePlanProfileStatus.pending
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DischargePlanProfileStatus.suspended || next == DischargePlanProfileStatus.closed
            case .suspended:
                return next == DischargePlanProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("discharge plan profile") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(attempts) - budget) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanProfile {
            return DischargePlanProfile(
                code: code,
                title: title,
                attempts: attempts,
                budget: budget,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan profile in status draft.
    static func newDischargePlanProfile(_ code: String, title: String) -> DischargePlanProfile {
        return DischargePlanProfile(
            code: code,
            title: title,
            attempts: 0,
            budget: 0.0,
            label: "",
            status: DischargePlanProfileStatus.draft
        )
    }
}
