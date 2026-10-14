import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility quota is in its life cycle.
    enum EligibilityQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a eligibility quota and its current status.
    final class EligibilityQuota {
        var code: String
        var label: String
        var quantity: Int
        var procedureCode: String
        var budget: Double
        var startsAt: Int
        var version: Int
        var status: EligibilityQuotaStatus

        init(code: String, label: String, quantity: Int, procedureCode: String, budget: Double, startsAt: Int, version: Int, status: EligibilityQuotaStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.budget = budget
            self.startsAt = startsAt
            self.version = version
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

        func canMoveTo(_ next: EligibilityQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == EligibilityQuotaStatus.approved || next == EligibilityQuotaStatus.withdrawn
            case .approved:
                return next == EligibilityQuotaStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: EligibilityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("eligibility quota") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(quantity) + budget) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityQuota {
            return EligibilityQuota(
                code: code,
                label: label,
                quantity: quantity,
                procedureCode: procedureCode,
                budget: budget,
                startsAt: startsAt,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility quota in status proposed.
    static func newEligibilityQuota(_ code: String, label: String) -> EligibilityQuota {
        return EligibilityQuota(
            code: code,
            label: label,
            quantity: 0,
            procedureCode: "",
            budget: 0.0,
            startsAt: 0,
            version: 0,
            status: EligibilityQuotaStatus.proposed
        )
    }
}
