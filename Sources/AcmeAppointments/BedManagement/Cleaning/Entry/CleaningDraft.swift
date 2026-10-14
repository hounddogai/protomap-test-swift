import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning draft is in its life cycle.
    enum CleaningDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A cleaning draft as the cleaning team keeps it.
    final class CleaningDraft {
        var code: String
        var title: String
        var archived: Bool
        var version: Int
        var limit: Int
        var status: CleaningDraftStatus

        init(code: String, title: String, archived: Bool, version: Int, limit: Int, status: CleaningDraftStatus) {
            self.code = code
            self.title = title
            self.archived = archived
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

        func canMoveTo(_ next: CleaningDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CleaningDraftStatus.active
            case .active:
                return next == CleaningDraftStatus.suspended || next == CleaningDraftStatus.closed
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

        func moveTo(_ next: CleaningDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("cleaning draft") \(code)"
        }

        func netValue() -> Double {
            return (Double(version) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> CleaningDraft {
            return CleaningDraft(
                code: code,
                title: title,
                archived: archived,
                version: version,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a cleaning draft in status draft.
    static func newCleaningDraft(_ code: String, title: String) -> CleaningDraft {
        return CleaningDraft(
            code: code,
            title: title,
            archived: false,
            version: 0,
            limit: 0,
            status: CleaningDraftStatus.draft
        )
    }
}
