import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual shift score is in its life cycle.
    enum ManualShiftScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual shift score as the shift team keeps it.
    final class ManualShiftScore {
        var code: String
        var name: String
        var startsAt: Int
        var channel: String
        var limit: Int
        var status: ManualShiftScoreStatus

        init(code: String, name: String, startsAt: Int, channel: String, limit: Int, status: ManualShiftScoreStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.channel = channel
            self.limit = limit
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

        func canMoveTo(_ next: ManualShiftScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualShiftScoreStatus.resolved || next == ManualShiftScoreStatus.archived
            case .inReview:
                return next == ManualShiftScoreStatus.resolved
            case .resolved:
                return next == ManualShiftScoreStatus.reopened || next == ManualShiftScoreStatus.archived
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

        func moveTo(_ next: ManualShiftScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual shift score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (Double(limit) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualShiftScore {
            return ManualShiftScore(
                code: code,
                name: name,
                startsAt: startsAt,
                channel: channel,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual shift score in status open.
    static func newManualShiftScore(_ code: String, name: String) -> ManualShiftScore {
        return ManualShiftScore(
            code: code,
            name: name,
            startsAt: 0,
            channel: "",
            limit: 0,
            status: ManualShiftScoreStatus.`open`
        )
    }
}
