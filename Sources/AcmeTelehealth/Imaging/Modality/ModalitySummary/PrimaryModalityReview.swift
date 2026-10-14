import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary modality review is in its life cycle.
    enum PrimaryModalityReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One primary modality review, with what the planners need to act on it.
    final class PrimaryModalityReview {
        var code: String
        var title: String
        var weight: Double
        var pinned: Bool
        var retries: Int
        var allergy: String
        var cost: Double
        var ceiling: Double
        var status: PrimaryModalityReviewStatus

        init(code: String, title: String, weight: Double, pinned: Bool, retries: Int, allergy: String, cost: Double, ceiling: Double, status: PrimaryModalityReviewStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.pinned = pinned
            self.retries = retries
            self.allergy = allergy
            self.cost = cost
            self.ceiling = ceiling
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

        func canMoveTo(_ next: PrimaryModalityReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryModalityReviewStatus.inReview || next == PrimaryModalityReviewStatus.reopened
            case .inReview:
                return next == PrimaryModalityReviewStatus.resolved || next == PrimaryModalityReviewStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PrimaryModalityReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryModalityReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary modality review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((cost - weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryModalityReview {
            return PrimaryModalityReview(
                code: code,
                title: title,
                weight: weight,
                pinned: pinned,
                retries: retries,
                allergy: allergy,
                cost: cost,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary modality review in status open.
    static func newPrimaryModalityReview(_ code: String, title: String) -> PrimaryModalityReview {
        return PrimaryModalityReview(
            code: code,
            title: title,
            weight: 0.0,
            pinned: false,
            retries: 0,
            allergy: "",
            cost: 0.0,
            ceiling: 0.0,
            status: PrimaryModalityReviewStatus.`open`
        )
    }
}
