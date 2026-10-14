import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist review is in its life cycle.
    enum WorklistReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A worklist review as the worklist team keeps it.
    final class WorklistReview {
        var code: String
        var label: String
        var updatedAt: Int
        var ownerID: String
        var margin: Double
        var specialty: String
        var minimum: Double
        var status: WorklistReviewStatus

        init(code: String, label: String, updatedAt: Int, ownerID: String, margin: Double, specialty: String, minimum: Double, status: WorklistReviewStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.ownerID = ownerID
            self.margin = margin
            self.specialty = specialty
            self.minimum = minimum
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

        func canMoveTo(_ next: WorklistReviewStatus) -> Bool {
            switch status {
            case .planned:
                return next == WorklistReviewStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == WorklistReviewStatus.completed || next == WorklistReviewStatus.cancelled
            case .completed:
                return next == WorklistReviewStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveExposure() -> Double {
            return ((margin - minimum) * 100).rounded() / 100
        }

        func copyValue() -> WorklistReview {
            return WorklistReview(
                code: code,
                label: label,
                updatedAt: updatedAt,
                ownerID: ownerID,
                margin: margin,
                specialty: specialty,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist review in status planned.
    static func newWorklistReview(_ code: String, label: String) -> WorklistReview {
        return WorklistReview(
            code: code,
            label: label,
            updatedAt: 0,
            ownerID: "",
            margin: 0.0,
            specialty: "",
            minimum: 0.0,
            status: WorklistReviewStatus.planned
        )
    }
}
