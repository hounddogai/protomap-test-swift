import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global priority quota is in its life cycle.
    enum GlobalPriorityQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global priority quota. Its code is unique within a tenant.
    final class GlobalPriorityQuota {
        var code: String
        var label: String
        var notes: String
        var updatedAt: Int
        var encounterID: String
        var checksum: String
        var segment: String
        var status: GlobalPriorityQuotaStatus

        init(code: String, label: String, notes: String, updatedAt: Int, encounterID: String, checksum: String, segment: String, status: GlobalPriorityQuotaStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.checksum = checksum
            self.segment = segment
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

        func canMoveTo(_ next: GlobalPriorityQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalPriorityQuotaStatus.published || next == GlobalPriorityQuotaStatus.retired
            case .validated:
                return next == GlobalPriorityQuotaStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: GlobalPriorityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global priority quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global priority quota") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> GlobalPriorityQuota {
            return GlobalPriorityQuota(
                code: code,
                label: label,
                notes: notes,
                updatedAt: updatedAt,
                encounterID: encounterID,
                checksum: checksum,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global priority quota in status created.
    static func newGlobalPriorityQuota(_ code: String, label: String) -> GlobalPriorityQuota {
        return GlobalPriorityQuota(
            code: code,
            label: label,
            notes: "",
            updatedAt: 0,
            encounterID: "",
            checksum: "",
            segment: "",
            status: GlobalPriorityQuotaStatus.created
        )
    }
}
