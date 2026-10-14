import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback dispense review is in its life cycle.
    enum FallbackDispenseReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback dispense review as the dispense team keeps it.
    final class FallbackDispenseReview {
        var code: String
        var title: String
        var margin: Double
        var name: String
        var label: String
        var score: Double
        var refills: Int
        var status: FallbackDispenseReviewStatus

        init(code: String, title: String, margin: Double, name: String, label: String, score: Double, refills: Int, status: FallbackDispenseReviewStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.name = name
            self.label = label
            self.score = score
            self.refills = refills
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

        func canMoveTo(_ next: FallbackDispenseReviewStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackDispenseReviewStatus.completed
            case .scheduled:
                return next == FallbackDispenseReviewStatus.completed
            case .inProgress:
                return next == FallbackDispenseReviewStatus.completed || next == FallbackDispenseReviewStatus.cancelled
            case .completed:
                return next == FallbackDispenseReviewStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDispenseReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback dispense review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback dispense review") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((margin - score) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDispenseReview {
            return FallbackDispenseReview(
                code: code,
                title: title,
                margin: margin,
                name: name,
                label: label,
                score: score,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback dispense review in status planned.
    static func newFallbackDispenseReview(_ code: String, title: String) -> FallbackDispenseReview {
        return FallbackDispenseReview(
            code: code,
            title: title,
            margin: 0.0,
            name: "",
            label: "",
            score: 0.0,
            refills: 0,
            status: FallbackDispenseReviewStatus.planned
        )
    }
}
