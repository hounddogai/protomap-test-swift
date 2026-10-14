import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global skill mix estimate is in its life cycle.
    enum GlobalSkillMixEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global skill mix estimate, with what the planners need to act on it.
    final class GlobalSkillMixEstimate {
        var code: String
        var title: String
        var budget: Double
        var updatedAt: Int
        var allergy: String
        var status: GlobalSkillMixEstimateStatus

        init(code: String, title: String, budget: Double, updatedAt: Int, allergy: String, status: GlobalSkillMixEstimateStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.updatedAt = updatedAt
            self.allergy = allergy
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

        func canMoveTo(_ next: GlobalSkillMixEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalSkillMixEstimateStatus.approved || next == GlobalSkillMixEstimateStatus.withdrawn
            case .approved:
                return next == GlobalSkillMixEstimateStatus.rejected
            case .rejected:
                return next == GlobalSkillMixEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSkillMixEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global skill mix estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(updatedAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSkillMixEstimate {
            return GlobalSkillMixEstimate(
                code: code,
                title: title,
                budget: budget,
                updatedAt: updatedAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global skill mix estimate in status proposed.
    static func newGlobalSkillMixEstimate(_ code: String, title: String) -> GlobalSkillMixEstimate {
        return GlobalSkillMixEstimate(
            code: code,
            title: title,
            budget: 0.0,
            updatedAt: 0,
            allergy: "",
            status: GlobalSkillMixEstimateStatus.proposed
        )
    }
}
