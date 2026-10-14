import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal score is in its life cycle.
    enum GoalScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a goal score and its current status.
    final class GoalScore {
        var code: String
        var title: String
        var contactEmail: String
        var weight: Double
        var visitMinutes: Int
        var maximum: Double
        var name: String
        var threshold: Double
        var timezone: String
        var refills: Int
        var status: GoalScoreStatus

        init(code: String, title: String, contactEmail: String, weight: Double, visitMinutes: Int, maximum: Double, name: String, threshold: Double, timezone: String, refills: Int, status: GoalScoreStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.name = name
            self.threshold = threshold
            self.timezone = timezone
            self.refills = refills
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

        func canMoveTo(_ next: GoalScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GoalScoreStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GoalScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(visitMinutes) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> GoalScore {
            return GoalScore(
                code: code,
                title: title,
                contactEmail: contactEmail,
                weight: weight,
                visitMinutes: visitMinutes,
                maximum: maximum,
                name: name,
                threshold: threshold,
                timezone: timezone,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a goal score in status open.
    static func newGoalScore(_ code: String, title: String) -> GoalScore {
        return GoalScore(
            code: code,
            title: title,
            contactEmail: "",
            weight: 0.0,
            visitMinutes: 0,
            maximum: 0.0,
            name: "",
            threshold: 0.0,
            timezone: "",
            refills: 0,
            status: GoalScoreStatus.`open`
        )
    }
}
