import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix audit is in its life cycle.
    enum SkillMixAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A skill mix audit as the skill mix team keeps it.
    final class SkillMixAudit {
        var code: String
        var title: String
        var reviewer: String
        var score: Double
        var copay: Double
        var approved: Bool
        var expiresAt: Int
        var status: SkillMixAuditStatus

        init(code: String, title: String, reviewer: String, score: Double, copay: Double, approved: Bool, expiresAt: Int, status: SkillMixAuditStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.score = score
            self.copay = copay
            self.approved = approved
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: SkillMixAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SkillMixAuditStatus.rejected
            case .rejected:
                return next == SkillMixAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(expiresAt) - score) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixAudit {
            return SkillMixAudit(
                code: code,
                title: title,
                reviewer: reviewer,
                score: score,
                copay: copay,
                approved: approved,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a skill mix audit in status proposed.
    static func newSkillMixAudit(_ code: String, title: String) -> SkillMixAudit {
        return SkillMixAudit(
            code: code,
            title: title,
            reviewer: "",
            score: 0.0,
            copay: 0.0,
            approved: false,
            expiresAt: 0,
            status: SkillMixAuditStatus.proposed
        )
    }
}
