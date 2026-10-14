import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility window is in its life cycle.
    enum EligibilityWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A eligibility window as the eligibility team keeps it.
    final class EligibilityWindow {
        var code: String
        var label: String
        var amount: Double
        var timezone: String
        var ward: String
        var pinned: Bool
        var status: EligibilityWindowStatus

        init(code: String, label: String, amount: Double, timezone: String, ward: String, pinned: Bool, status: EligibilityWindowStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.timezone = timezone
            self.ward = ward
            self.pinned = pinned
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

        func canMoveTo(_ next: EligibilityWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == EligibilityWindowStatus.pending
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == EligibilityWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("eligibility window") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> EligibilityWindow {
            return EligibilityWindow(
                code: code,
                label: label,
                amount: amount,
                timezone: timezone,
                ward: ward,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a eligibility window in status draft.
    static func newEligibilityWindow(_ code: String, label: String) -> EligibilityWindow {
        return EligibilityWindow(
            code: code,
            label: label,
            amount: 0.0,
            timezone: "",
            ward: "",
            pinned: false,
            status: EligibilityWindowStatus.draft
        )
    }
}
