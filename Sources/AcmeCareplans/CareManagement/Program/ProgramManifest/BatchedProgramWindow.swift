import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched program window is in its life cycle.
    enum BatchedProgramWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One batched program window, with what the planners need to act on it.
    final class BatchedProgramWindow {
        var code: String
        var title: String
        var archived: Bool
        var expiresAt: Int
        var bed: String
        var externalRef: String
        var procedureCode: String
        var category: String
        var status: BatchedProgramWindowStatus

        init(code: String, title: String, archived: Bool, expiresAt: Int, bed: String, externalRef: String, procedureCode: String, category: String, status: BatchedProgramWindowStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.expiresAt = expiresAt
            self.bed = bed
            self.externalRef = externalRef
            self.procedureCode = procedureCode
            self.category = category
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

        func canMoveTo(_ next: BatchedProgramWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedProgramWindowStatus.active
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedProgramWindowStatus.closed
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

        func moveTo(_ next: BatchedProgramWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched program window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> BatchedProgramWindow {
            return BatchedProgramWindow(
                code: code,
                title: title,
                archived: archived,
                expiresAt: expiresAt,
                bed: bed,
                externalRef: externalRef,
                procedureCode: procedureCode,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched program window in status draft.
    static func newBatchedProgramWindow(_ code: String, title: String) -> BatchedProgramWindow {
        return BatchedProgramWindow(
            code: code,
            title: title,
            archived: false,
            expiresAt: 0,
            bed: "",
            externalRef: "",
            procedureCode: "",
            category: "",
            status: BatchedProgramWindowStatus.draft
        )
    }
}
