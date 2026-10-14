import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score entry is in its life cycle.
    enum RiskScoreEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A risk score entry as the risk score team keeps it.
    final class RiskScoreEntry {
        var code: String
        var title: String
        var discount: Double
        var channel: String
        var tags: [String]
        var summary: String
        var limit: Int
        var score: Double
        var startsAt: Int
        var reviewer: String
        var timezone: String
        var status: RiskScoreEntryStatus

        init(code: String, title: String, discount: Double, channel: String, tags: [String], summary: String, limit: Int, score: Double, startsAt: Int, reviewer: String, timezone: String, status: RiskScoreEntryStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.channel = channel
            self.tags = tags
            self.summary = summary
            self.limit = limit
            self.score = score
            self.startsAt = startsAt
            self.reviewer = reviewer
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RiskScoreEntryStatus.ready || next == RiskScoreEntryStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RiskScoreEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((Double(limit) + score) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreEntry {
            return RiskScoreEntry(
                code: code,
                title: title,
                discount: discount,
                channel: channel,
                tags: tags,
                summary: summary,
                limit: limit,
                score: score,
                startsAt: startsAt,
                reviewer: reviewer,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a risk score entry in status idle.
    static func newRiskScoreEntry(_ code: String, title: String) -> RiskScoreEntry {
        return RiskScoreEntry(
            code: code,
            title: title,
            discount: 0.0,
            channel: "",
            tags: [],
            summary: "",
            limit: 0,
            score: 0.0,
            startsAt: 0,
            reviewer: "",
            timezone: "",
            status: RiskScoreEntryStatus.idle
        )
    }
}
