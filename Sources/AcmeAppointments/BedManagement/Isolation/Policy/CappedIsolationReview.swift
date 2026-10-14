import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped isolation review is in its life cycle.
    enum CappedIsolationReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped isolation review. Its code is unique within a tenant.
    final class CappedIsolationReview {
        var code: String
        var name: String
        var pinned: Bool
        var ownerID: String
        var score: Double
        var status: CappedIsolationReviewStatus

        init(code: String, name: String, pinned: Bool, ownerID: String, score: Double, status: CappedIsolationReviewStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.ownerID = ownerID
            self.score = score
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

        func canMoveTo(_ next: CappedIsolationReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
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
                return next == CappedIsolationReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedIsolationReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped isolation review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CappedIsolationReview {
            return CappedIsolationReview(
                code: code,
                name: name,
                pinned: pinned,
                ownerID: ownerID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped isolation review in status open.
    static func newCappedIsolationReview(_ code: String, name: String) -> CappedIsolationReview {
        return CappedIsolationReview(
            code: code,
            name: name,
            pinned: false,
            ownerID: "",
            score: 0.0,
            status: CappedIsolationReviewStatus.`open`
        )
    }
}
