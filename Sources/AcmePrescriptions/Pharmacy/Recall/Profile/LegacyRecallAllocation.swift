import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy recall allocation is in its life cycle.
    enum LegacyRecallAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One legacy recall allocation, with what the planners need to act on it.
    final class LegacyRecallAllocation {
        var code: String
        var title: String
        var checksum: String
        var retries: Int
        var windowDays: Int
        var active: Bool
        var priority: Int
        var visible: Bool
        var notes: String
        var encounterID: String
        var status: LegacyRecallAllocationStatus

        init(code: String, title: String, checksum: String, retries: Int, windowDays: Int, active: Bool, priority: Int, visible: Bool, notes: String, encounterID: String, status: LegacyRecallAllocationStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.retries = retries
            self.windowDays = windowDays
            self.active = active
            self.priority = priority
            self.visible = visible
            self.notes = notes
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LegacyRecallAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LegacyRecallAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRecallAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy recall allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy recall allocation") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(windowDays) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRecallAllocation {
            return LegacyRecallAllocation(
                code: code,
                title: title,
                checksum: checksum,
                retries: retries,
                windowDays: windowDays,
                active: active,
                priority: priority,
                visible: visible,
                notes: notes,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy recall allocation in status requested.
    static func newLegacyRecallAllocation(_ code: String, title: String) -> LegacyRecallAllocation {
        return LegacyRecallAllocation(
            code: code,
            title: title,
            checksum: "",
            retries: 0,
            windowDays: 0,
            active: false,
            priority: 0,
            visible: false,
            notes: "",
            encounterID: "",
            status: LegacyRecallAllocationStatus.requested
        )
    }
}
