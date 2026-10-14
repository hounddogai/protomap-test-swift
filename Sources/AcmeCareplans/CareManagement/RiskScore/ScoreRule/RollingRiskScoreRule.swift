import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling risk score rule is in its life cycle.
    enum RollingRiskScoreRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling risk score rule and its current status.
    final class RollingRiskScoreRule {
        var code: String
        var title: String
        var budget: Double
        var tags: [String]
        var sequence: Int
        var limit: Int
        var status: RollingRiskScoreRuleStatus

        init(code: String, title: String, budget: Double, tags: [String], sequence: Int, limit: Int, status: RollingRiskScoreRuleStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.tags = tags
            self.sequence = sequence
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingRiskScoreRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingRiskScoreRuleStatus.done
            case .done:
                return next == RollingRiskScoreRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingRiskScoreRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling risk score rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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
            return ((Double(sequence) - budget) * 100).rounded() / 100
        }

        func copyValue() -> RollingRiskScoreRule {
            return RollingRiskScoreRule(
                code: code,
                title: title,
                budget: budget,
                tags: tags,
                sequence: sequence,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling risk score rule in status new.
    static func newRollingRiskScoreRule(_ code: String, title: String) -> RollingRiskScoreRule {
        return RollingRiskScoreRule(
            code: code,
            title: title,
            budget: 0.0,
            tags: [],
            sequence: 0,
            limit: 0,
            status: RollingRiskScoreRuleStatus.new
        )
    }
}
