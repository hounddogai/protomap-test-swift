import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled claim snapshot is in its life cycle.
    enum ScheduledClaimSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a scheduled claim snapshot and its current status.
    final class ScheduledClaimSnapshot {
        var code: String
        var name: String
        var active: Bool
        var limit: Int
        var contactEmail: String
        var segment: String
        var status: ScheduledClaimSnapshotStatus

        init(code: String, name: String, active: Bool, limit: Int, contactEmail: String, segment: String, status: ScheduledClaimSnapshotStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.limit = limit
            self.contactEmail = contactEmail
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledClaimSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledClaimSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled claim snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled claim snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> ScheduledClaimSnapshot {
            return ScheduledClaimSnapshot(
                code: code,
                name: name,
                active: active,
                limit: limit,
                contactEmail: contactEmail,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled claim snapshot in status proposed.
    static func newScheduledClaimSnapshot(_ code: String, name: String) -> ScheduledClaimSnapshot {
        return ScheduledClaimSnapshot(
            code: code,
            name: name,
            active: false,
            limit: 0,
            contactEmail: "",
            segment: "",
            status: ScheduledClaimSnapshotStatus.proposed
        )
    }
}
