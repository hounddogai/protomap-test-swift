import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary study review is in its life cycle.
    enum PrimaryStudyReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a primary study review and its current status.
    final class PrimaryStudyReview {
        var code: String
        var label: String
        var source: String
        var startsAt: Int
        var archived: Bool
        var attempts: Int
        var unit: String
        var status: PrimaryStudyReviewStatus

        init(code: String, label: String, source: String, startsAt: Int, archived: Bool, attempts: Int, unit: String, status: PrimaryStudyReviewStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.startsAt = startsAt
            self.archived = archived
            self.attempts = attempts
            self.unit = unit
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

        func canMoveTo(_ next: PrimaryStudyReviewStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PrimaryStudyReviewStatus.draining || next == PrimaryStudyReviewStatus.stopped
            case .draining:
                return next == PrimaryStudyReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryStudyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary study review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return (Double(attempts) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStudyReview {
            return PrimaryStudyReview(
                code: code,
                label: label,
                source: source,
                startsAt: startsAt,
                archived: archived,
                attempts: attempts,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary study review in status idle.
    static func newPrimaryStudyReview(_ code: String, label: String) -> PrimaryStudyReview {
        return PrimaryStudyReview(
            code: code,
            label: label,
            source: "",
            startsAt: 0,
            archived: false,
            attempts: 0,
            unit: "",
            status: PrimaryStudyReviewStatus.idle
        )
    }
}
