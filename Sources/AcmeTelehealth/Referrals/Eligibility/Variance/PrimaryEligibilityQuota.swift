import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary eligibility quota is in its life cycle.
    enum PrimaryEligibilityQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary eligibility quota, with what the planners need to act on it.
    final class PrimaryEligibilityQuota {
        var code: String
        var label: String
        var diagnosisCode: String
        var createdAt: Int
        var retries: Int
        var status: PrimaryEligibilityQuotaStatus

        init(code: String, label: String, diagnosisCode: String, createdAt: Int, retries: Int, status: PrimaryEligibilityQuotaStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.retries = retries
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

        func canMoveTo(_ next: PrimaryEligibilityQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryEligibilityQuotaStatus.granted || next == PrimaryEligibilityQuotaStatus.expired
            case .granted:
                return next == PrimaryEligibilityQuotaStatus.revoked || next == PrimaryEligibilityQuotaStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryEligibilityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary eligibility quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("primary eligibility quota") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(createdAt) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryEligibilityQuota {
            return PrimaryEligibilityQuota(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary eligibility quota in status requested.
    static func newPrimaryEligibilityQuota(_ code: String, label: String) -> PrimaryEligibilityQuota {
        return PrimaryEligibilityQuota(
            code: code,
            label: label,
            diagnosisCode: "",
            createdAt: 0,
            retries: 0,
            status: PrimaryEligibilityQuotaStatus.requested
        )
    }
}
