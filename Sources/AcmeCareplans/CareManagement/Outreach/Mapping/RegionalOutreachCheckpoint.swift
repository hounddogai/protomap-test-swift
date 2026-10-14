import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional outreach checkpoint is in its life cycle.
    enum RegionalOutreachCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a regional outreach checkpoint and its current status.
    final class RegionalOutreachCheckpoint {
        var code: String
        var label: String
        var priority: Int
        var encounterID: String
        var limit: Int
        var segment: String
        var pinned: Bool
        var batchSize: Int
        var copay: Double
        var status: RegionalOutreachCheckpointStatus

        init(code: String, label: String, priority: Int, encounterID: String, limit: Int, segment: String, pinned: Bool, batchSize: Int, copay: Double, status: RegionalOutreachCheckpointStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.encounterID = encounterID
            self.limit = limit
            self.segment = segment
            self.pinned = pinned
            self.batchSize = batchSize
            self.copay = copay
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

        func canMoveTo(_ next: RegionalOutreachCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
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
                return next == RegionalOutreachCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOutreachCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional outreach checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional outreach checkpoint") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(priority) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOutreachCheckpoint {
            return RegionalOutreachCheckpoint(
                code: code,
                label: label,
                priority: priority,
                encounterID: encounterID,
                limit: limit,
                segment: segment,
                pinned: pinned,
                batchSize: batchSize,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional outreach checkpoint in status requested.
    static func newRegionalOutreachCheckpoint(_ code: String, label: String) -> RegionalOutreachCheckpoint {
        return RegionalOutreachCheckpoint(
            code: code,
            label: label,
            priority: 0,
            encounterID: "",
            limit: 0,
            segment: "",
            pinned: false,
            batchSize: 0,
            copay: 0.0,
            status: RegionalOutreachCheckpointStatus.requested
        )
    }
}
