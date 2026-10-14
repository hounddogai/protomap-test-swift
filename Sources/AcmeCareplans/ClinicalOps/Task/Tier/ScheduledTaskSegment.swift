import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled task segment is in its life cycle.
    enum ScheduledTaskSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a scheduled task segment and its current status.
    final class ScheduledTaskSegment {
        var code: String
        var label: String
        var attempts: Int
        var approved: Bool
        var segment: String
        var contactEmail: String
        var retries: Int
        var status: ScheduledTaskSegmentStatus

        init(code: String, label: String, attempts: Int, approved: Bool, segment: String, contactEmail: String, retries: Int, status: ScheduledTaskSegmentStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.approved = approved
            self.segment = segment
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ScheduledTaskSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledTaskSegmentStatus.suspended || next == ScheduledTaskSegmentStatus.closed
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

        func moveTo(_ next: ScheduledTaskSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled task segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(attempts) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledTaskSegment {
            return ScheduledTaskSegment(
                code: code,
                label: label,
                attempts: attempts,
                approved: approved,
                segment: segment,
                contactEmail: contactEmail,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled task segment in status draft.
    static func newScheduledTaskSegment(_ code: String, label: String) -> ScheduledTaskSegment {
        return ScheduledTaskSegment(
            code: code,
            label: label,
            attempts: 0,
            approved: false,
            segment: "",
            contactEmail: "",
            retries: 0,
            status: ScheduledTaskSegmentStatus.draft
        )
    }
}
