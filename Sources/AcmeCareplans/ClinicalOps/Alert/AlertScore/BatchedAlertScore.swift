import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched alert score is in its life cycle.
    enum BatchedAlertScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched alert score. Its code is unique within a tenant.
    final class BatchedAlertScore {
        var code: String
        var title: String
        var channel: String
        var contactEmail: String
        var visitMinutes: Int
        var category: String
        var timezone: String
        var patientRef: String
        var status: BatchedAlertScoreStatus

        init(code: String, title: String, channel: String, contactEmail: String, visitMinutes: Int, category: String, timezone: String, patientRef: String, status: BatchedAlertScoreStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.category = category
            self.timezone = timezone
            self.patientRef = patientRef
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

        func canMoveTo(_ next: BatchedAlertScoreStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedAlertScoreStatus.suspended || next == BatchedAlertScoreStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedAlertScoreStatus.suspended || next == BatchedAlertScoreStatus.closed
            case .suspended:
                return next == BatchedAlertScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAlertScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched alert score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched alert score") \(code)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> BatchedAlertScore {
            return BatchedAlertScore(
                code: code,
                title: title,
                channel: channel,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                category: category,
                timezone: timezone,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched alert score in status draft.
    static func newBatchedAlertScore(_ code: String, title: String) -> BatchedAlertScore {
        return BatchedAlertScore(
            code: code,
            title: title,
            channel: "",
            contactEmail: "",
            visitMinutes: 0,
            category: "",
            timezone: "",
            patientRef: "",
            status: BatchedAlertScoreStatus.draft
        )
    }
}
