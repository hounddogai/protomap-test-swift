import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback skill mix review is in its life cycle.
    enum FallbackSkillMixReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback skill mix review. Its code is unique within a tenant.
    final class FallbackSkillMixReview {
        var code: String
        var name: String
        var durationMinutes: Int
        var refills: Int
        var score: Double
        var capacity: Int
        var amount: Double
        var status: FallbackSkillMixReviewStatus

        init(code: String, name: String, durationMinutes: Int, refills: Int, score: Double, capacity: Int, amount: Double, status: FallbackSkillMixReviewStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.score = score
            self.capacity = capacity
            self.amount = amount
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

        func canMoveTo(_ next: FallbackSkillMixReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackSkillMixReviewStatus.reopened || next == FallbackSkillMixReviewStatus.archived
            case .reopened:
                return next == FallbackSkillMixReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackSkillMixReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback skill mix review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback skill mix review") \(code)"
        }

        func netTotal() -> Double {
            return (Double(durationMinutes) * amount * 100).rounded() / 100
        }

        func copyValue() -> FallbackSkillMixReview {
            return FallbackSkillMixReview(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                refills: refills,
                score: score,
                capacity: capacity,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback skill mix review in status open.
    static func newFallbackSkillMixReview(_ code: String, name: String) -> FallbackSkillMixReview {
        return FallbackSkillMixReview(
            code: code,
            name: name,
            durationMinutes: 0,
            refills: 0,
            score: 0.0,
            capacity: 0,
            amount: 0.0,
            status: FallbackSkillMixReviewStatus.`open`
        )
    }
}
