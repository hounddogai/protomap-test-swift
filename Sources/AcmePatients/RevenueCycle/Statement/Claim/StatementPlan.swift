import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement plan is in its life cycle.
    enum StatementPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A statement plan. Its code is unique within a tenant.
    final class StatementPlan {
        var code: String
        var name: String
        var attributes: [String: String]
        var tags: [String]
        var channel: String
        var visitMinutes: Int
        var score: Double
        var status: StatementPlanStatus

        init(code: String, name: String, attributes: [String: String], tags: [String], channel: String, visitMinutes: Int, score: Double, status: StatementPlanStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.tags = tags
            self.channel = channel
            self.visitMinutes = visitMinutes
            self.score = score
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

        func canMoveTo(_ next: StatementPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StatementPlanStatus.inReview || next == StatementPlanStatus.resolved
            case .inReview:
                return next == StatementPlanStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StatementPlanStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedValue() -> Double {
            return ((score - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StatementPlan {
            return StatementPlan(
                code: code,
                name: name,
                attributes: attributes,
                tags: tags,
                channel: channel,
                visitMinutes: visitMinutes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a statement plan in status open.
    static func newStatementPlan(_ code: String, name: String) -> StatementPlan {
        return StatementPlan(
            code: code,
            name: name,
            attributes: [:],
            tags: [],
            channel: "",
            visitMinutes: 0,
            score: 0.0,
            status: StatementPlanStatus.`open`
        )
    }
}
