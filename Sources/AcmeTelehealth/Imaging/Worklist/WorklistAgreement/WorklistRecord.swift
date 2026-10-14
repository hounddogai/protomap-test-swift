import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist record is in its life cycle.
    enum WorklistRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A worklist record. Its code is unique within a tenant.
    final class WorklistRecord {
        var code: String
        var label: String
        var description: String
        var contactEmail: String
        var endsAt: Int
        var status: WorklistRecordStatus

        init(code: String, label: String, description: String, contactEmail: String, endsAt: Int, status: WorklistRecordStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.contactEmail = contactEmail
            self.endsAt = endsAt
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

        func canMoveTo(_ next: WorklistRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == WorklistRecordStatus.pending || next == WorklistRecordStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WorklistRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> WorklistRecord {
            return WorklistRecord(
                code: code,
                label: label,
                description: description,
                contactEmail: contactEmail,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist record in status draft.
    static func newWorklistRecord(_ code: String, label: String) -> WorklistRecord {
        return WorklistRecord(
            code: code,
            label: label,
            description: "",
            contactEmail: "",
            endsAt: 0,
            status: WorklistRecordStatus.draft
        )
    }
}
