import AcmePlatform
import Foundation

extension Labs {
    /// Where a global specimen review is in its life cycle.
    enum GlobalSpecimenReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One global specimen review, with what the planners need to act on it.
    final class GlobalSpecimenReview {
        var code: String
        var name: String
        var version: Int
        var notes: String
        var summary: String
        var status: GlobalSpecimenReviewStatus

        init(code: String, name: String, version: Int, notes: String, summary: String, status: GlobalSpecimenReviewStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.notes = notes
            self.summary = summary
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

        func canMoveTo(_ next: GlobalSpecimenReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalSpecimenReviewStatus.archived
            case .inReview:
                return next == GlobalSpecimenReviewStatus.resolved || next == GlobalSpecimenReviewStatus.archived
            case .resolved:
                return next == GlobalSpecimenReviewStatus.reopened || next == GlobalSpecimenReviewStatus.archived
            case .reopened:
                return next == GlobalSpecimenReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSpecimenReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global specimen review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("global specimen review") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> GlobalSpecimenReview {
            return GlobalSpecimenReview(
                code: code,
                name: name,
                version: version,
                notes: notes,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global specimen review in status open.
    static func newGlobalSpecimenReview(_ code: String, name: String) -> GlobalSpecimenReview {
        return GlobalSpecimenReview(
            code: code,
            name: name,
            version: 0,
            notes: "",
            summary: "",
            status: GlobalSpecimenReviewStatus.`open`
        )
    }
}
