import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled eligibility plan is in its life cycle.
    enum ScheduledEligibilityPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a scheduled eligibility plan and its current status.
    final class ScheduledEligibilityPlan {
        var code: String
        var name: String
        var ownerID: String
        var limit: Int
        var budget: Double
        var locale: String
        var description: String
        var allergy: String
        var updatedAt: Int
        var externalRef: String
        var clinicianID: String
        var status: ScheduledEligibilityPlanStatus

        init(code: String, name: String, ownerID: String, limit: Int, budget: Double, locale: String, description: String, allergy: String, updatedAt: Int, externalRef: String, clinicianID: String, status: ScheduledEligibilityPlanStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.limit = limit
            self.budget = budget
            self.locale = locale
            self.description = description
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ScheduledEligibilityPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ScheduledEligibilityPlanStatus.revoked || next == ScheduledEligibilityPlanStatus.expired
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

        func moveTo(_ next: ScheduledEligibilityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled eligibility plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled eligibility plan") \(code)"
        }

        func netLoad() -> Double {
            return (Double(limit) * budget * 100).rounded() / 100
        }

        func copyValue() -> ScheduledEligibilityPlan {
            return ScheduledEligibilityPlan(
                code: code,
                name: name,
                ownerID: ownerID,
                limit: limit,
                budget: budget,
                locale: locale,
                description: description,
                allergy: allergy,
                updatedAt: updatedAt,
                externalRef: externalRef,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled eligibility plan in status requested.
    static func newScheduledEligibilityPlan(_ code: String, name: String) -> ScheduledEligibilityPlan {
        return ScheduledEligibilityPlan(
            code: code,
            name: name,
            ownerID: "",
            limit: 0,
            budget: 0.0,
            locale: "",
            description: "",
            allergy: "",
            updatedAt: 0,
            externalRef: "",
            clinicianID: "",
            status: ScheduledEligibilityPlanStatus.requested
        )
    }
}
