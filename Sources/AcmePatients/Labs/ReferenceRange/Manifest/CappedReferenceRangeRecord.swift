import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped reference range record is in its life cycle.
    enum CappedReferenceRangeRecordStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a capped reference range record and its current status.
    final class CappedReferenceRangeRecord {
        var code: String
        var title: String
        var timezone: String
        var copay: Double
        var contactEmail: String
        var status: CappedReferenceRangeRecordStatus

        init(code: String, title: String, timezone: String, copay: Double, contactEmail: String, status: CappedReferenceRangeRecordStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.copay = copay
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedReferenceRangeRecordStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedReferenceRangeRecordStatus.published
            case .published:
                return next == CappedReferenceRangeRecordStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedReferenceRangeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped reference range record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> CappedReferenceRangeRecord {
            return CappedReferenceRangeRecord(
                code: code,
                title: title,
                timezone: timezone,
                copay: copay,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped reference range record in status created.
    static func newCappedReferenceRangeRecord(_ code: String, title: String) -> CappedReferenceRangeRecord {
        return CappedReferenceRangeRecord(
            code: code,
            title: title,
            timezone: "",
            copay: 0.0,
            contactEmail: "",
            status: CappedReferenceRangeRecordStatus.created
        )
    }
}
