import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched skill mix estimate is in its life cycle.
    enum BatchedSkillMixEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched skill mix estimate as the skill mix team keeps it.
    final class BatchedSkillMixEstimate {
        var code: String
        var title: String
        var minimum: Double
        var reviewer: String
        var timezone: String
        var ownerID: String
        var revision: Int
        var status: BatchedSkillMixEstimateStatus

        init(code: String, title: String, minimum: Double, reviewer: String, timezone: String, ownerID: String, revision: Int, status: BatchedSkillMixEstimateStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.reviewer = reviewer
            self.timezone = timezone
            self.ownerID = ownerID
            self.revision = revision
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

        func canMoveTo(_ next: BatchedSkillMixEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedSkillMixEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSkillMixEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched skill mix estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("batched skill mix estimate") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(revision) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSkillMixEstimate {
            return BatchedSkillMixEstimate(
                code: code,
                title: title,
                minimum: minimum,
                reviewer: reviewer,
                timezone: timezone,
                ownerID: ownerID,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched skill mix estimate in status requested.
    static func newBatchedSkillMixEstimate(_ code: String, title: String) -> BatchedSkillMixEstimate {
        return BatchedSkillMixEstimate(
            code: code,
            title: title,
            minimum: 0.0,
            reviewer: "",
            timezone: "",
            ownerID: "",
            revision: 0,
            status: BatchedSkillMixEstimateStatus.requested
        )
    }
}
