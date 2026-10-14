import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled result policy is in its life cycle.
    enum ScheduledResultPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled result policy as the result team keeps it.
    final class ScheduledResultPolicy {
        var code: String
        var title: String
        var source: String
        var segment: String
        var reviewer: String
        var score: Double
        var floorValue: Double
        var startsAt: Int
        var retries: Int
        var description: String
        var limit: Int
        var status: ScheduledResultPolicyStatus

        init(code: String, title: String, source: String, segment: String, reviewer: String, score: Double, floorValue: Double, startsAt: Int, retries: Int, description: String, limit: Int, status: ScheduledResultPolicyStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.segment = segment
            self.reviewer = reviewer
            self.score = score
            self.floorValue = floorValue
            self.startsAt = startsAt
            self.retries = retries
            self.description = description
            self.limit = limit
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

        func canMoveTo(_ next: ScheduledResultPolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ScheduledResultPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledResultPolicy {
            return ScheduledResultPolicy(
                code: code,
                title: title,
                source: source,
                segment: segment,
                reviewer: reviewer,
                score: score,
                floorValue: floorValue,
                startsAt: startsAt,
                retries: retries,
                description: description,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled result policy in status planned.
    static func newScheduledResultPolicy(_ code: String, title: String) -> ScheduledResultPolicy {
        return ScheduledResultPolicy(
            code: code,
            title: title,
            source: "",
            segment: "",
            reviewer: "",
            score: 0.0,
            floorValue: 0.0,
            startsAt: 0,
            retries: 0,
            description: "",
            limit: 0,
            status: ScheduledResultPolicyStatus.planned
        )
    }
}
