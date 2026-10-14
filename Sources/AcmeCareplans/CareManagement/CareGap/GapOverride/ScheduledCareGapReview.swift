import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled care gap review is in its life cycle.
    enum ScheduledCareGapReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled care gap review and its current status.
    final class ScheduledCareGapReview {
        var code: String
        var label: String
        var tags: [String]
        var amount: Double
        var region: String
        var status: ScheduledCareGapReviewStatus

        init(code: String, label: String, tags: [String], amount: Double, region: String, status: ScheduledCareGapReviewStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.amount = amount
            self.region = region
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

        func canMoveTo(_ next: ScheduledCareGapReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledCareGapReviewStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ScheduledCareGapReviewStatus.draining || next == ScheduledCareGapReviewStatus.stopped
            case .draining:
                return next == ScheduledCareGapReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareGapReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care gap review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled care gap review") \(code)"
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
            return amount
        }

        func copyValue() -> ScheduledCareGapReview {
            return ScheduledCareGapReview(
                code: code,
                label: label,
                tags: tags,
                amount: amount,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled care gap review in status idle.
    static func newScheduledCareGapReview(_ code: String, label: String) -> ScheduledCareGapReview {
        return ScheduledCareGapReview(
            code: code,
            label: label,
            tags: [],
            amount: 0.0,
            region: "",
            status: ScheduledCareGapReviewStatus.idle
        )
    }
}
