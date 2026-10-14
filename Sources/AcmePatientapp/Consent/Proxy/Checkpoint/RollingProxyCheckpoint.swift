import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling proxy checkpoint is in its life cycle.
    enum RollingProxyCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling proxy checkpoint and its current status.
    final class RollingProxyCheckpoint {
        var code: String
        var label: String
        var encounterID: String
        var maximum: Double
        var expiresAt: Int
        var ownerID: String
        var updatedAt: Int
        var cost: Double
        var refills: Int
        var minimum: Double
        var timezone: String
        var status: RollingProxyCheckpointStatus

        init(code: String, label: String, encounterID: String, maximum: Double, expiresAt: Int, ownerID: String, updatedAt: Int, cost: Double, refills: Int, minimum: Double, timezone: String, status: RollingProxyCheckpointStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.cost = cost
            self.refills = refills
            self.minimum = minimum
            self.timezone = timezone
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

        func canMoveTo(_ next: RollingProxyCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingProxyCheckpointStatus.scheduled || next == RollingProxyCheckpointStatus.inProgress
            case .scheduled:
                return next == RollingProxyCheckpointStatus.inProgress || next == RollingProxyCheckpointStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingProxyCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingProxyCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling proxy checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rolling proxy checkpoint") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(expiresAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> RollingProxyCheckpoint {
            return RollingProxyCheckpoint(
                code: code,
                label: label,
                encounterID: encounterID,
                maximum: maximum,
                expiresAt: expiresAt,
                ownerID: ownerID,
                updatedAt: updatedAt,
                cost: cost,
                refills: refills,
                minimum: minimum,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling proxy checkpoint in status planned.
    static func newRollingProxyCheckpoint(_ code: String, label: String) -> RollingProxyCheckpoint {
        return RollingProxyCheckpoint(
            code: code,
            label: label,
            encounterID: "",
            maximum: 0.0,
            expiresAt: 0,
            ownerID: "",
            updatedAt: 0,
            cost: 0.0,
            refills: 0,
            minimum: 0.0,
            timezone: "",
            status: RollingProxyCheckpointStatus.planned
        )
    }
}
