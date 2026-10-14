import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled transfer profile is in its life cycle.
    enum ScheduledTransferProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled transfer profile. Its code is unique within a tenant.
    final class ScheduledTransferProfile {
        var code: String
        var label: String
        var limit: Int
        var encounterID: String
        var archived: Bool
        var status: ScheduledTransferProfileStatus

        init(code: String, label: String, limit: Int, encounterID: String, archived: Bool, status: ScheduledTransferProfileStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.encounterID = encounterID
            self.archived = archived
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

        func canMoveTo(_ next: ScheduledTransferProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledTransferProfileStatus.granted || next == ScheduledTransferProfileStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledTransferProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled transfer profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> ScheduledTransferProfile {
            return ScheduledTransferProfile(
                code: code,
                label: label,
                limit: limit,
                encounterID: encounterID,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled transfer profile in status requested.
    static func newScheduledTransferProfile(_ code: String, label: String) -> ScheduledTransferProfile {
        return ScheduledTransferProfile(
            code: code,
            label: label,
            limit: 0,
            encounterID: "",
            archived: false,
            status: ScheduledTransferProfileStatus.requested
        )
    }
}
