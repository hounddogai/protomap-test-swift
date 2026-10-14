import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal claim is in its life cycle.
    enum GoalClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a goal claim and its current status.
    final class GoalClaim {
        var code: String
        var name: String
        var budget: Double
        var tags: [String]
        var batchSize: Int
        var status: GoalClaimStatus

        init(code: String, name: String, budget: Double, tags: [String], batchSize: Int, status: GoalClaimStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.tags = tags
            self.batchSize = batchSize
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

        func canMoveTo(_ next: GoalClaimStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GoalClaimStatus.reopened || next == GoalClaimStatus.archived
            case .inReview:
                return next == GoalClaimStatus.resolved
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

        func moveTo(_ next: GoalClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return (Double(batchSize) * budget * 100).rounded() / 100
        }

        func copyValue() -> GoalClaim {
            return GoalClaim(
                code: code,
                name: name,
                budget: budget,
                tags: tags,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a goal claim in status open.
    static func newGoalClaim(_ code: String, name: String) -> GoalClaim {
        return GoalClaim(code: code, name: name, budget: 0.0, tags: [], batchSize: 0, status: GoalClaimStatus.`open`)
    }
}
