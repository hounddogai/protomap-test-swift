import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched program draft is in its life cycle.
    enum BatchedProgramDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched program draft. Its code is unique within a tenant.
    final class BatchedProgramDraft {
        var code: String
        var title: String
        var limit: Int
        var notes: String
        var priority: Int
        var externalRef: String
        var status: BatchedProgramDraftStatus

        init(code: String, title: String, limit: Int, notes: String, priority: Int, externalRef: String, status: BatchedProgramDraftStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.notes = notes
            self.priority = priority
            self.externalRef = externalRef
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

        func canMoveTo(_ next: BatchedProgramDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedProgramDraftStatus.revoked || next == BatchedProgramDraftStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BatchedProgramDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched program draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched program draft") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(priority) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProgramDraft {
            return BatchedProgramDraft(
                code: code,
                title: title,
                limit: limit,
                notes: notes,
                priority: priority,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched program draft in status requested.
    static func newBatchedProgramDraft(_ code: String, title: String) -> BatchedProgramDraft {
        return BatchedProgramDraft(
            code: code,
            title: title,
            limit: 0,
            notes: "",
            priority: 0,
            externalRef: "",
            status: BatchedProgramDraftStatus.requested
        )
    }
}
