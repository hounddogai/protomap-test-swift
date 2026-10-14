import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix estimate is in its life cycle.
    enum SkillMixEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One skill mix estimate, with what the planners need to act on it.
    final class SkillMixEstimate {
        var code: String
        var title: String
        var contactEmail: String
        var updatedAt: Int
        var description: String
        var timezone: String
        var patientRef: String
        var copay: Double
        var score: Double
        var status: SkillMixEstimateStatus

        init(code: String, title: String, contactEmail: String, updatedAt: Int, description: String, timezone: String, patientRef: String, copay: Double, score: Double, status: SkillMixEstimateStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.description = description
            self.timezone = timezone
            self.patientRef = patientRef
            self.copay = copay
            self.score = score
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

        func canMoveTo(_ next: SkillMixEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == SkillMixEstimateStatus.granted || next == SkillMixEstimateStatus.revoked
            case .granted:
                return next == SkillMixEstimateStatus.expired
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

        func moveTo(_ next: SkillMixEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("skill mix estimate") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(updatedAt) + copay) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixEstimate {
            return SkillMixEstimate(
                code: code,
                title: title,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                description: description,
                timezone: timezone,
                patientRef: patientRef,
                copay: copay,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a skill mix estimate in status requested.
    static func newSkillMixEstimate(_ code: String, title: String) -> SkillMixEstimate {
        return SkillMixEstimate(
            code: code,
            title: title,
            contactEmail: "",
            updatedAt: 0,
            description: "",
            timezone: "",
            patientRef: "",
            copay: 0.0,
            score: 0.0,
            status: SkillMixEstimateStatus.requested
        )
    }
}
