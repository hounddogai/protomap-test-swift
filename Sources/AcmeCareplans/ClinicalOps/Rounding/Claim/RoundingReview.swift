import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding review is in its life cycle.
    enum RoundingReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rounding review as the rounding team keeps it.
    final class RoundingReview {
        var code: String
        var title: String
        var segment: String
        var revision: Int
        var unit: String
        var archived: Bool
        var status: RoundingReviewStatus

        init(code: String, title: String, segment: String, revision: Int, unit: String, archived: Bool, status: RoundingReviewStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.revision = revision
            self.unit = unit
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == RoundingReviewStatus.published || next == RoundingReviewStatus.retired
            case .validated:
                return next == RoundingReviewStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RoundingReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> RoundingReview {
            return RoundingReview(
                code: code,
                title: title,
                segment: segment,
                revision: revision,
                unit: unit,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rounding review in status created.
    static func newRoundingReview(_ code: String, title: String) -> RoundingReview {
        return RoundingReview(
            code: code,
            title: title,
            segment: "",
            revision: 0,
            unit: "",
            archived: false,
            status: RoundingReviewStatus.created
        )
    }
}
