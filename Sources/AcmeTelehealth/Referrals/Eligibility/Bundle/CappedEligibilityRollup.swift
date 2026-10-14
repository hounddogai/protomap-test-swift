import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped eligibility rollup is in its life cycle.
    enum CappedEligibilityRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One capped eligibility rollup, with what the planners need to act on it.
    final class CappedEligibilityRollup {
        var code: String
        var label: String
        var refills: Int
        var name: String
        var active: Bool
        var locale: String
        var attempts: Int
        var approved: Bool
        var discount: Double
        var status: CappedEligibilityRollupStatus

        init(code: String, label: String, refills: Int, name: String, active: Bool, locale: String, attempts: Int, approved: Bool, discount: Double, status: CappedEligibilityRollupStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.name = name
            self.active = active
            self.locale = locale
            self.attempts = attempts
            self.approved = approved
            self.discount = discount
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

        func canMoveTo(_ next: CappedEligibilityRollupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedEligibilityRollupStatus.approved || next == CappedEligibilityRollupStatus.rejected
            case .approved:
                return next == CappedEligibilityRollupStatus.rejected || next == CappedEligibilityRollupStatus.withdrawn
            case .rejected:
                return next == CappedEligibilityRollupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedEligibilityRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped eligibility rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return (discount * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> CappedEligibilityRollup {
            return CappedEligibilityRollup(
                code: code,
                label: label,
                refills: refills,
                name: name,
                active: active,
                locale: locale,
                attempts: attempts,
                approved: approved,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped eligibility rollup in status proposed.
    static func newCappedEligibilityRollup(_ code: String, label: String) -> CappedEligibilityRollup {
        return CappedEligibilityRollup(
            code: code,
            label: label,
            refills: 0,
            name: "",
            active: false,
            locale: "",
            attempts: 0,
            approved: false,
            discount: 0.0,
            status: CappedEligibilityRollupStatus.proposed
        )
    }
}
