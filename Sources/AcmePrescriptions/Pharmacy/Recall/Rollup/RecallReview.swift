import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall review is in its life cycle.
    enum RecallReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One recall review, with what the planners need to act on it.
    final class RecallReview {
        var code: String
        var name: String
        var updatedAt: Int
        var endsAt: Int
        var source: String
        var notes: String
        var status: RecallReviewStatus

        init(code: String, name: String, updatedAt: Int, endsAt: Int, source: String, notes: String, status: RecallReviewStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.source = source
            self.notes = notes
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

        func canMoveTo(_ next: RecallReviewStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RecallReviewStatus.running || next == RecallReviewStatus.failed
            case .running:
                return next == RecallReviewStatus.done || next == RecallReviewStatus.failed
            case .done:
                return next == RecallReviewStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedVolume() -> Double {
            return ((Double(endsAt) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> RecallReview {
            return RecallReview(
                code: code,
                name: name,
                updatedAt: updatedAt,
                endsAt: endsAt,
                source: source,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a recall review in status new.
    static func newRecallReview(_ code: String, name: String) -> RecallReview {
        return RecallReview(
            code: code,
            name: name,
            updatedAt: 0,
            endsAt: 0,
            source: "",
            notes: "",
            status: RecallReviewStatus.new
        )
    }
}
