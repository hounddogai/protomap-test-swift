import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality review is in its life cycle.
    enum ModalityReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One modality review, with what the planners need to act on it.
    final class ModalityReview {
        var code: String
        var title: String
        var sequence: Int
        var channel: String
        var amount: Double
        var tags: [String]
        var rate: Double
        var status: ModalityReviewStatus

        init(code: String, title: String, sequence: Int, channel: String, amount: Double, tags: [String], rate: Double, status: ModalityReviewStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.channel = channel
            self.amount = amount
            self.tags = tags
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == ModalityReviewStatus.suspended || next == ModalityReviewStatus.closed
            case .pending:
                return next == ModalityReviewStatus.active
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ModalityReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((Double(sequence) + rate) * 100).rounded() / 100
        }

        func copyValue() -> ModalityReview {
            return ModalityReview(
                code: code,
                title: title,
                sequence: sequence,
                channel: channel,
                amount: amount,
                tags: tags,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a modality review in status draft.
    static func newModalityReview(_ code: String, title: String) -> ModalityReview {
        return ModalityReview(
            code: code,
            title: title,
            sequence: 0,
            channel: "",
            amount: 0.0,
            tags: [],
            rate: 0.0,
            status: ModalityReviewStatus.draft
        )
    }
}
