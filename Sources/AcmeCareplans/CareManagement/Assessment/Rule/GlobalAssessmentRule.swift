import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global assessment rule is in its life cycle.
    enum GlobalAssessmentRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global assessment rule as the assessment team keeps it.
    final class GlobalAssessmentRule {
        var code: String
        var name: String
        var sequence: Int
        var discount: Double
        var endsAt: Int
        var budget: Double
        var status: GlobalAssessmentRuleStatus

        init(code: String, name: String, sequence: Int, discount: Double, endsAt: Int, budget: Double, status: GlobalAssessmentRuleStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.discount = discount
            self.endsAt = endsAt
            self.budget = budget
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

        func canMoveTo(_ next: GlobalAssessmentRuleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalAssessmentRuleStatus.approved
            case .approved:
                return next == GlobalAssessmentRuleStatus.withdrawn
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

        func moveTo(_ next: GlobalAssessmentRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global assessment rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return (Double(endsAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> GlobalAssessmentRule {
            return GlobalAssessmentRule(
                code: code,
                name: name,
                sequence: sequence,
                discount: discount,
                endsAt: endsAt,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global assessment rule in status proposed.
    static func newGlobalAssessmentRule(_ code: String, name: String) -> GlobalAssessmentRule {
        return GlobalAssessmentRule(
            code: code,
            name: name,
            sequence: 0,
            discount: 0.0,
            endsAt: 0,
            budget: 0.0,
            status: GlobalAssessmentRuleStatus.proposed
        )
    }
}
