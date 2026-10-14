import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched care protocol review is in its life cycle.
    enum BatchedCareProtocolReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched care protocol review and its current status.
    final class BatchedCareProtocolReview {
        var code: String
        var title: String
        var startsAt: Int
        var timezone: String
        var graceDays: Int
        var limit: Int
        var status: BatchedCareProtocolReviewStatus

        init(code: String, title: String, startsAt: Int, timezone: String, graceDays: Int, limit: Int, status: BatchedCareProtocolReviewStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.timezone = timezone
            self.graceDays = graceDays
            self.limit = limit
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

        func canMoveTo(_ next: BatchedCareProtocolReviewStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedCareProtocolReviewStatus.stopped
            case .ready:
                return next == BatchedCareProtocolReviewStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedCareProtocolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care protocol review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((Double(graceDays) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareProtocolReview {
            return BatchedCareProtocolReview(
                code: code,
                title: title,
                startsAt: startsAt,
                timezone: timezone,
                graceDays: graceDays,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched care protocol review in status idle.
    static func newBatchedCareProtocolReview(_ code: String, title: String) -> BatchedCareProtocolReview {
        return BatchedCareProtocolReview(
            code: code,
            title: title,
            startsAt: 0,
            timezone: "",
            graceDays: 0,
            limit: 0,
            status: BatchedCareProtocolReviewStatus.idle
        )
    }
}
