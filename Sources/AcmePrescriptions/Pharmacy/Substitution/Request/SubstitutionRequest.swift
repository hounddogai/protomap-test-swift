import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution request is in its life cycle.
    enum SubstitutionRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A substitution request. Its code is unique within a tenant.
    final class SubstitutionRequest {
        var code: String
        var title: String
        var durationMinutes: Int
        var locale: String
        var tags: [String]
        var quantity: Int
        var pinned: Bool
        var approved: Bool
        var reviewer: String
        var status: SubstitutionRequestStatus

        init(code: String, title: String, durationMinutes: Int, locale: String, tags: [String], quantity: Int, pinned: Bool, approved: Bool, reviewer: String, status: SubstitutionRequestStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.locale = locale
            self.tags = tags
            self.quantity = quantity
            self.pinned = pinned
            self.approved = approved
            self.reviewer = reviewer
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

        func canMoveTo(_ next: SubstitutionRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == SubstitutionRequestStatus.pending || next == SubstitutionRequestStatus.suspended
            case .pending:
                return next == SubstitutionRequestStatus.suspended || next == SubstitutionRequestStatus.closed
            case .active:
                return next == SubstitutionRequestStatus.suspended
            case .suspended:
                return next == SubstitutionRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func projectedLoad() -> Double {
            return ((Double(quantity) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionRequest {
            return SubstitutionRequest(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                locale: locale,
                tags: tags,
                quantity: quantity,
                pinned: pinned,
                approved: approved,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a substitution request in status draft.
    static func newSubstitutionRequest(_ code: String, title: String) -> SubstitutionRequest {
        return SubstitutionRequest(
            code: code,
            title: title,
            durationMinutes: 0,
            locale: "",
            tags: [],
            quantity: 0,
            pinned: false,
            approved: false,
            reviewer: "",
            status: SubstitutionRequestStatus.draft
        )
    }
}
