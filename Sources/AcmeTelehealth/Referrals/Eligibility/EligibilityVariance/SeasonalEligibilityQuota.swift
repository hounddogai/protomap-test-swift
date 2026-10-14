import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal eligibility quota is in its life cycle.
    enum SeasonalEligibilityQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a seasonal eligibility quota and its current status.
    final class SeasonalEligibilityQuota {
        var code: String
        var name: String
        var phone: String
        var updatedAt: Int
        var createdAt: Int
        var allergy: String
        var contactEmail: String
        var acuity: Int
        var score: Double
        var reviewer: String
        var threshold: Double
        var status: SeasonalEligibilityQuotaStatus

        init(code: String, name: String, phone: String, updatedAt: Int, createdAt: Int, allergy: String, contactEmail: String, acuity: Int, score: Double, reviewer: String, threshold: Double, status: SeasonalEligibilityQuotaStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.score = score
            self.reviewer = reviewer
            self.threshold = threshold
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

        func canMoveTo(_ next: SeasonalEligibilityQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalEligibilityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal eligibility quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return (Double(createdAt) * score * 100).rounded() / 100
        }

        func copyValue() -> SeasonalEligibilityQuota {
            return SeasonalEligibilityQuota(
                code: code,
                name: name,
                phone: phone,
                updatedAt: updatedAt,
                createdAt: createdAt,
                allergy: allergy,
                contactEmail: contactEmail,
                acuity: acuity,
                score: score,
                reviewer: reviewer,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal eligibility quota in status proposed.
    static func newSeasonalEligibilityQuota(_ code: String, name: String) -> SeasonalEligibilityQuota {
        return SeasonalEligibilityQuota(
            code: code,
            name: name,
            phone: "",
            updatedAt: 0,
            createdAt: 0,
            allergy: "",
            contactEmail: "",
            acuity: 0,
            score: 0.0,
            reviewer: "",
            threshold: 0.0,
            status: SeasonalEligibilityQuotaStatus.proposed
        )
    }
}
