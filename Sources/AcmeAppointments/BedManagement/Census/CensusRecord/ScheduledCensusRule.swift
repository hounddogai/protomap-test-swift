import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled census rule is in its life cycle.
    enum ScheduledCensusRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled census rule as the census team keeps it.
    final class ScheduledCensusRule {
        var code: String
        var title: String
        var region: String
        var createdAt: Int
        var revision: Int
        var copay: Double
        var ownerID: String
        var status: ScheduledCensusRuleStatus

        init(code: String, title: String, region: String, createdAt: Int, revision: Int, copay: Double, ownerID: String, status: ScheduledCensusRuleStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.createdAt = createdAt
            self.revision = revision
            self.copay = copay
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ScheduledCensusRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledCensusRuleStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ScheduledCensusRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCensusRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled census rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("scheduled census rule") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(revision) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCensusRule {
            return ScheduledCensusRule(
                code: code,
                title: title,
                region: region,
                createdAt: createdAt,
                revision: revision,
                copay: copay,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled census rule in status open.
    static func newScheduledCensusRule(_ code: String, title: String) -> ScheduledCensusRule {
        return ScheduledCensusRule(
            code: code,
            title: title,
            region: "",
            createdAt: 0,
            revision: 0,
            copay: 0.0,
            ownerID: "",
            status: ScheduledCensusRuleStatus.`open`
        )
    }
}
