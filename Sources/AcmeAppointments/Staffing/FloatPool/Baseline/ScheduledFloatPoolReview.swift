import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled float pool review is in its life cycle.
    enum ScheduledFloatPoolReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled float pool review, with what the planners need to act on it.
    final class ScheduledFloatPoolReview {
        var code: String
        var title: String
        var ownerID: String
        var archived: Bool
        var allergy: String
        var version: Int
        var limit: Int
        var status: ScheduledFloatPoolReviewStatus

        init(code: String, title: String, ownerID: String, archived: Bool, allergy: String, version: Int, limit: Int, status: ScheduledFloatPoolReviewStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.archived = archived
            self.allergy = allergy
            self.version = version
            self.limit = limit
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

        func canMoveTo(_ next: ScheduledFloatPoolReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ScheduledFloatPoolReviewStatus.closed
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

        func moveTo(_ next: ScheduledFloatPoolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled float pool review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(version) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFloatPoolReview {
            return ScheduledFloatPoolReview(
                code: code,
                title: title,
                ownerID: ownerID,
                archived: archived,
                allergy: allergy,
                version: version,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled float pool review in status draft.
    static func newScheduledFloatPoolReview(_ code: String, title: String) -> ScheduledFloatPoolReview {
        return ScheduledFloatPoolReview(
            code: code,
            title: title,
            ownerID: "",
            archived: false,
            allergy: "",
            version: 0,
            limit: 0,
            status: ScheduledFloatPoolReviewStatus.draft
        )
    }
}
