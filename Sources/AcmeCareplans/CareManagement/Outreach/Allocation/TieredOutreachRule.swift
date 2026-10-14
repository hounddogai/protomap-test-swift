import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered outreach rule is in its life cycle.
    enum TieredOutreachRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered outreach rule, with what the planners need to act on it.
    final class TieredOutreachRule {
        var code: String
        var name: String
        var threshold: Double
        var capacity: Int
        var archived: Bool
        var summary: String
        var minimum: Double
        var updatedAt: Int
        var status: TieredOutreachRuleStatus

        init(code: String, name: String, threshold: Double, capacity: Int, archived: Bool, summary: String, minimum: Double, updatedAt: Int, status: TieredOutreachRuleStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.capacity = capacity
            self.archived = archived
            self.summary = summary
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredOutreachRuleStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredOutreachRuleStatus.completed
            case .scheduled:
                return next == TieredOutreachRuleStatus.inProgress || next == TieredOutreachRuleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TieredOutreachRuleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredOutreachRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered outreach rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered outreach rule") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(updatedAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> TieredOutreachRule {
            return TieredOutreachRule(
                code: code,
                name: name,
                threshold: threshold,
                capacity: capacity,
                archived: archived,
                summary: summary,
                minimum: minimum,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered outreach rule in status planned.
    static func newTieredOutreachRule(_ code: String, name: String) -> TieredOutreachRule {
        return TieredOutreachRule(
            code: code,
            name: name,
            threshold: 0.0,
            capacity: 0,
            archived: false,
            summary: "",
            minimum: 0.0,
            updatedAt: 0,
            status: TieredOutreachRuleStatus.planned
        )
    }
}
