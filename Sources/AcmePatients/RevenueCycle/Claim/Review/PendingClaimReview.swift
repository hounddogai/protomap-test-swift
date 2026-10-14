import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending claim review is in its life cycle.
    enum PendingClaimReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending claim review, with what the planners need to act on it.
    final class PendingClaimReview {
        var code: String
        var title: String
        var weight: Double
        var capacity: Int
        var retries: Int
        var category: String
        var amount: Double
        var batchSize: Int
        var attempts: Int
        var status: PendingClaimReviewStatus

        init(code: String, title: String, weight: Double, capacity: Int, retries: Int, category: String, amount: Double, batchSize: Int, attempts: Int, status: PendingClaimReviewStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.capacity = capacity
            self.retries = retries
            self.category = category
            self.amount = amount
            self.batchSize = batchSize
            self.attempts = attempts
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

        func canMoveTo(_ next: PendingClaimReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingClaimReviewStatus.running
            case .queued:
                return next == PendingClaimReviewStatus.done || next == PendingClaimReviewStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PendingClaimReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending claim review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(retries) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PendingClaimReview {
            return PendingClaimReview(
                code: code,
                title: title,
                weight: weight,
                capacity: capacity,
                retries: retries,
                category: category,
                amount: amount,
                batchSize: batchSize,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending claim review in status new.
    static func newPendingClaimReview(_ code: String, title: String) -> PendingClaimReview {
        return PendingClaimReview(
            code: code,
            title: title,
            weight: 0.0,
            capacity: 0,
            retries: 0,
            category: "",
            amount: 0.0,
            batchSize: 0,
            attempts: 0,
            status: PendingClaimReviewStatus.new
        )
    }
}
