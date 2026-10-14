import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot record is in its life cycle.
    enum BatchedSlotRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched slot record as the slot team keeps it.
    final class BatchedSlotRecord {
        var code: String
        var title: String
        var approved: Bool
        var summary: String
        var phone: String
        var windowDays: Int
        var clinicianID: String
        var priority: Int
        var timezone: String
        var status: BatchedSlotRecordStatus

        init(code: String, title: String, approved: Bool, summary: String, phone: String, windowDays: Int, clinicianID: String, priority: Int, timezone: String, status: BatchedSlotRecordStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.summary = summary
            self.phone = phone
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.priority = priority
            self.timezone = timezone
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

        func canMoveTo(_ next: BatchedSlotRecordStatus) -> Bool {
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
                return next == BatchedSlotRecordStatus.revoked || next == BatchedSlotRecordStatus.expired
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

        func moveTo(_ next: BatchedSlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return (Double(priority) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSlotRecord {
            return BatchedSlotRecord(
                code: code,
                title: title,
                approved: approved,
                summary: summary,
                phone: phone,
                windowDays: windowDays,
                clinicianID: clinicianID,
                priority: priority,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched slot record in status requested.
    static func newBatchedSlotRecord(_ code: String, title: String) -> BatchedSlotRecord {
        return BatchedSlotRecord(
            code: code,
            title: title,
            approved: false,
            summary: "",
            phone: "",
            windowDays: 0,
            clinicianID: "",
            priority: 0,
            timezone: "",
            status: BatchedSlotRecordStatus.requested
        )
    }
}
