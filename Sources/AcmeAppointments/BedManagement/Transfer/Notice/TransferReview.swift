import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer review is in its life cycle.
    enum TransferReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One transfer review, with what the planners need to act on it.
    final class TransferReview {
        var code: String
        var name: String
        var limit: Int
        var contactEmail: String
        var title: String
        var capacity: Int
        var status: TransferReviewStatus

        init(code: String, name: String, limit: Int, contactEmail: String, title: String, capacity: Int, status: TransferReviewStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.contactEmail = contactEmail
            self.title = title
            self.capacity = capacity
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

        func canMoveTo(_ next: TransferReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TransferReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return ((Double(limit) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> TransferReview {
            return TransferReview(
                code: code,
                name: name,
                limit: limit,
                contactEmail: contactEmail,
                title: title,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer review in status open.
    static func newTransferReview(_ code: String, name: String) -> TransferReview {
        return TransferReview(
            code: code,
            name: name,
            limit: 0,
            contactEmail: "",
            title: "",
            capacity: 0,
            status: TransferReviewStatus.`open`
        )
    }
}
