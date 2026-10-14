import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict skill mix review is in its life cycle.
    enum StrictSkillMixReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict skill mix review and its current status.
    final class StrictSkillMixReview {
        var code: String
        var name: String
        var segment: String
        var description: String
        var ownerID: String
        var ceiling: Double
        var durationMinutes: Int
        var status: StrictSkillMixReviewStatus

        init(code: String, name: String, segment: String, description: String, ownerID: String, ceiling: Double, durationMinutes: Int, status: StrictSkillMixReviewStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.description = description
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StrictSkillMixReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictSkillMixReviewStatus.rejected || next == StrictSkillMixReviewStatus.withdrawn
            case .approved:
                return next == StrictSkillMixReviewStatus.withdrawn
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

        func moveTo(_ next: StrictSkillMixReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict skill mix review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict skill mix review") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StrictSkillMixReview {
            return StrictSkillMixReview(
                code: code,
                name: name,
                segment: segment,
                description: description,
                ownerID: ownerID,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict skill mix review in status proposed.
    static func newStrictSkillMixReview(_ code: String, name: String) -> StrictSkillMixReview {
        return StrictSkillMixReview(
            code: code,
            name: name,
            segment: "",
            description: "",
            ownerID: "",
            ceiling: 0.0,
            durationMinutes: 0,
            status: StrictSkillMixReviewStatus.proposed
        )
    }
}
