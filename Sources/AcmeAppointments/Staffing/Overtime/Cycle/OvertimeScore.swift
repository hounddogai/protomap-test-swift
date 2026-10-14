import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime score is in its life cycle.
    enum OvertimeScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One overtime score, with what the planners need to act on it.
    final class OvertimeScore {
        var code: String
        var title: String
        var weight: Double
        var description: String
        var currency: String
        var amount: Double
        var limit: Int
        var channel: String
        var status: OvertimeScoreStatus

        init(code: String, title: String, weight: Double, description: String, currency: String, amount: Double, limit: Int, channel: String, status: OvertimeScoreStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.description = description
            self.currency = currency
            self.amount = amount
            self.limit = limit
            self.channel = channel
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

        func canMoveTo(_ next: OvertimeScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == OvertimeScoreStatus.reopened || next == OvertimeScoreStatus.archived
            case .reopened:
                return next == OvertimeScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) + weight) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeScore {
            return OvertimeScore(
                code: code,
                title: title,
                weight: weight,
                description: description,
                currency: currency,
                amount: amount,
                limit: limit,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a overtime score in status open.
    static func newOvertimeScore(_ code: String, title: String) -> OvertimeScore {
        return OvertimeScore(
            code: code,
            title: title,
            weight: 0.0,
            description: "",
            currency: "",
            amount: 0.0,
            limit: 0,
            channel: "",
            status: OvertimeScoreStatus.`open`
        )
    }
}
