import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal agreement is in its life cycle.
    enum GoalAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a goal agreement and its current status.
    final class GoalAgreement {
        var code: String
        var name: String
        var ceiling: Double
        var cost: Double
        var contactEmail: String
        var status: GoalAgreementStatus

        init(code: String, name: String, ceiling: Double, cost: Double, contactEmail: String, status: GoalAgreementStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.cost = cost
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GoalAgreementStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: GoalAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return ((cost + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> GoalAgreement {
            return GoalAgreement(
                code: code,
                name: name,
                ceiling: ceiling,
                cost: cost,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a goal agreement in status open.
    static func newGoalAgreement(_ code: String, name: String) -> GoalAgreement {
        return GoalAgreement(
            code: code,
            name: name,
            ceiling: 0.0,
            cost: 0.0,
            contactEmail: "",
            status: GoalAgreementStatus.`open`
        )
    }
}
