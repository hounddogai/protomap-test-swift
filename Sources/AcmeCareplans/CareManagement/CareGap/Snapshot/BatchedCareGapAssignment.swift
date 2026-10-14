import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched care gap assignment is in its life cycle.
    enum BatchedCareGapAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched care gap assignment as the care gap team keeps it.
    final class BatchedCareGapAssignment {
        var code: String
        var title: String
        var visitMinutes: Int
        var source: String
        var reviewer: String
        var summary: String
        var payer: String
        var revision: Int
        var retries: Int
        var status: BatchedCareGapAssignmentStatus

        init(code: String, title: String, visitMinutes: Int, source: String, reviewer: String, summary: String, payer: String, revision: Int, retries: Int, status: BatchedCareGapAssignmentStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.source = source
            self.reviewer = reviewer
            self.summary = summary
            self.payer = payer
            self.revision = revision
            self.retries = retries
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

        func canMoveTo(_ next: BatchedCareGapAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedCareGapAssignmentStatus.active
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: BatchedCareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(revision) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareGapAssignment {
            return BatchedCareGapAssignment(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                source: source,
                reviewer: reviewer,
                summary: summary,
                payer: payer,
                revision: revision,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched care gap assignment in status draft.
    static func newBatchedCareGapAssignment(_ code: String, title: String) -> BatchedCareGapAssignment {
        return BatchedCareGapAssignment(
            code: code,
            title: title,
            visitMinutes: 0,
            source: "",
            reviewer: "",
            summary: "",
            payer: "",
            revision: 0,
            retries: 0,
            status: BatchedCareGapAssignmentStatus.draft
        )
    }
}
