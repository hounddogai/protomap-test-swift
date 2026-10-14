import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range review is in its life cycle.
    enum ReferenceRangeReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a reference range review and its current status.
    final class ReferenceRangeReview {
        var code: String
        var title: String
        var notes: String
        var amount: Double
        var ownerID: String
        var status: ReferenceRangeReviewStatus

        init(code: String, title: String, notes: String, amount: Double, ownerID: String, status: ReferenceRangeReviewStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.amount = amount
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReferenceRangeReviewStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReferenceRangeReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("reference range review") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ReferenceRangeReview {
            return ReferenceRangeReview(
                code: code,
                title: title,
                notes: notes,
                amount: amount,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a reference range review in status requested.
    static func newReferenceRangeReview(_ code: String, title: String) -> ReferenceRangeReview {
        return ReferenceRangeReview(
            code: code,
            title: title,
            notes: "",
            amount: 0.0,
            ownerID: "",
            status: ReferenceRangeReviewStatus.requested
        )
    }
}
