import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled closure rollup is in its life cycle.
    enum ScheduledClosureRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled closure rollup. Its code is unique within a tenant.
    final class ScheduledClosureRollup {
        var code: String
        var title: String
        var weight: Double
        var currency: String
        var tags: [String]
        var payer: String
        var channel: String
        var encounterID: String
        var status: ScheduledClosureRollupStatus

        init(code: String, title: String, weight: Double, currency: String, tags: [String], payer: String, channel: String, encounterID: String, status: ScheduledClosureRollupStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.currency = currency
            self.tags = tags
            self.payer = payer
            self.channel = channel
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ScheduledClosureRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ScheduledClosureRollupStatus.reopened
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

        func moveTo(_ next: ScheduledClosureRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled closure rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> ScheduledClosureRollup {
            return ScheduledClosureRollup(
                code: code,
                title: title,
                weight: weight,
                currency: currency,
                tags: tags,
                payer: payer,
                channel: channel,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled closure rollup in status open.
    static func newScheduledClosureRollup(_ code: String, title: String) -> ScheduledClosureRollup {
        return ScheduledClosureRollup(
            code: code,
            title: title,
            weight: 0.0,
            currency: "",
            tags: [],
            payer: "",
            channel: "",
            encounterID: "",
            status: ScheduledClosureRollupStatus.`open`
        )
    }
}
