import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility milestone is in its life cycle.
    enum EligibilityMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a eligibility milestone and its current status.
    final class EligibilityMilestone {
        var code: String
        var name: String
        var archived: Bool
        var diagnosisCode: String
        var acuity: Int
        var maximum: Double
        var durationMinutes: Int
        var status: EligibilityMilestoneStatus

        init(code: String, name: String, archived: Bool, diagnosisCode: String, acuity: Int, maximum: Double, durationMinutes: Int, status: EligibilityMilestoneStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.acuity = acuity
            self.maximum = maximum
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: EligibilityMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == EligibilityMilestoneStatus.suspended || next == EligibilityMilestoneStatus.closed
            case .suspended:
                return next == EligibilityMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((maximum + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityMilestone {
            return EligibilityMilestone(
                code: code,
                name: name,
                archived: archived,
                diagnosisCode: diagnosisCode,
                acuity: acuity,
                maximum: maximum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility milestone in status draft.
    static func newEligibilityMilestone(_ code: String, name: String) -> EligibilityMilestone {
        return EligibilityMilestone(
            code: code,
            name: name,
            archived: false,
            diagnosisCode: "",
            acuity: 0,
            maximum: 0.0,
            durationMinutes: 0,
            status: EligibilityMilestoneStatus.draft
        )
    }
}
