import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study review is in its life cycle.
    enum StudyReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One study review, with what the planners need to act on it.
    final class StudyReview {
        var code: String
        var title: String
        var attempts: Int
        var tags: [String]
        var batchSize: Int
        var pinned: Bool
        var amount: Double
        var unit: String
        var status: StudyReviewStatus

        init(code: String, title: String, attempts: Int, tags: [String], batchSize: Int, pinned: Bool, amount: Double, unit: String, status: StudyReviewStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.tags = tags
            self.batchSize = batchSize
            self.pinned = pinned
            self.amount = amount
            self.unit = unit
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

        func canMoveTo(_ next: StudyReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == StudyReviewStatus.published || next == StudyReviewStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StudyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("study review") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((Double(batchSize) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> StudyReview {
            return StudyReview(
                code: code,
                title: title,
                attempts: attempts,
                tags: tags,
                batchSize: batchSize,
                pinned: pinned,
                amount: amount,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a study review in status created.
    static func newStudyReview(_ code: String, title: String) -> StudyReview {
        return StudyReview(
            code: code,
            title: title,
            attempts: 0,
            tags: [],
            batchSize: 0,
            pinned: false,
            amount: 0.0,
            unit: "",
            status: StudyReviewStatus.created
        )
    }
}
