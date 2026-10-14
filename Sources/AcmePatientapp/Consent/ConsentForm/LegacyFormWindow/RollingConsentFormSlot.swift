import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form slot is in its life cycle.
    enum RollingConsentFormSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rolling consent form slot, with what the planners need to act on it.
    final class RollingConsentFormSlot {
        var code: String
        var label: String
        var version: Int
        var ownerID: String
        var batchSize: Int
        var status: RollingConsentFormSlotStatus

        init(code: String, label: String, version: Int, ownerID: String, batchSize: Int, status: RollingConsentFormSlotStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingConsentFormSlotStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingConsentFormSlotStatus.scheduled
            case .scheduled:
                return next == RollingConsentFormSlotStatus.inProgress || next == RollingConsentFormSlotStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingConsentFormSlotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingConsentFormSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return ((Double(batchSize) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RollingConsentFormSlot {
            return RollingConsentFormSlot(
                code: code,
                label: label,
                version: version,
                ownerID: ownerID,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling consent form slot in status planned.
    static func newRollingConsentFormSlot(_ code: String, label: String) -> RollingConsentFormSlot {
        return RollingConsentFormSlot(
            code: code,
            label: label,
            version: 0,
            ownerID: "",
            batchSize: 0,
            status: RollingConsentFormSlotStatus.planned
        )
    }
}
