import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility rule is in its life cycle.
    enum EligibilityRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a eligibility rule and its current status.
    final class EligibilityRule {
        var code: String
        var name: String
        var minimum: Double
        var weight: Double
        var refills: Int
        var dosageMg: Double
        var windowDays: Int
        var attempts: Int
        var currency: String
        var revision: Int
        var status: EligibilityRuleStatus

        init(code: String, name: String, minimum: Double, weight: Double, refills: Int, dosageMg: Double, windowDays: Int, attempts: Int, currency: String, revision: Int, status: EligibilityRuleStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.weight = weight
            self.refills = refills
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.attempts = attempts
            self.currency = currency
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == EligibilityRuleStatus.granted || next == EligibilityRuleStatus.revoked
            case .granted:
                return next == EligibilityRuleStatus.revoked || next == EligibilityRuleStatus.expired
            case .revoked:
                return next == EligibilityRuleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return ((Double(attempts) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityRule {
            return EligibilityRule(
                code: code,
                name: name,
                minimum: minimum,
                weight: weight,
                refills: refills,
                dosageMg: dosageMg,
                windowDays: windowDays,
                attempts: attempts,
                currency: currency,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility rule in status requested.
    static func newEligibilityRule(_ code: String, name: String) -> EligibilityRule {
        return EligibilityRule(
            code: code,
            name: name,
            minimum: 0.0,
            weight: 0.0,
            refills: 0,
            dosageMg: 0.0,
            windowDays: 0,
            attempts: 0,
            currency: "",
            revision: 0,
            status: EligibilityRuleStatus.requested
        )
    }
}
