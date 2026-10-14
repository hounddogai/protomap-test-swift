import AcmePlatform
import Foundation

extension Labs {
    /// Where a global specimen exception is in its life cycle.
    enum GlobalSpecimenExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global specimen exception. Its code is unique within a tenant.
    final class GlobalSpecimenException {
        var code: String
        var title: String
        var retries: Int
        var version: Int
        var tags: [String]
        var archived: Bool
        var status: GlobalSpecimenExceptionStatus

        init(code: String, title: String, retries: Int, version: Int, tags: [String], archived: Bool, status: GlobalSpecimenExceptionStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.version = version
            self.tags = tags
            self.archived = archived
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

        func canMoveTo(_ next: GlobalSpecimenExceptionStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == GlobalSpecimenExceptionStatus.suspended
            case .active:
                return next == GlobalSpecimenExceptionStatus.suspended
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

        func moveTo(_ next: GlobalSpecimenExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global specimen exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((Double(version) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSpecimenException {
            return GlobalSpecimenException(
                code: code,
                title: title,
                retries: retries,
                version: version,
                tags: tags,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global specimen exception in status draft.
    static func newGlobalSpecimenException(_ code: String, title: String) -> GlobalSpecimenException {
        return GlobalSpecimenException(
            code: code,
            title: title,
            retries: 0,
            version: 0,
            tags: [],
            archived: false,
            status: GlobalSpecimenExceptionStatus.draft
        )
    }
}
