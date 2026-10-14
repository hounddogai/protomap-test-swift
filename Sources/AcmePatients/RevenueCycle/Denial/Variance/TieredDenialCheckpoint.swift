import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered denial checkpoint is in its life cycle.
    enum TieredDenialCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One tiered denial checkpoint, with what the planners need to act on it.
    final class TieredDenialCheckpoint {
        var code: String
        var label: String
        var refills: Int
        var version: Int
        var encounterID: String
        var facility: String
        var status: TieredDenialCheckpointStatus

        init(code: String, label: String, refills: Int, version: Int, encounterID: String, facility: String, status: TieredDenialCheckpointStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.version = version
            self.encounterID = encounterID
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredDenialCheckpointStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredDenialCheckpointStatus.running || next == TieredDenialCheckpointStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: TieredDenialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered denial checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("tiered denial checkpoint") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(refills) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> TieredDenialCheckpoint {
            return TieredDenialCheckpoint(
                code: code,
                label: label,
                refills: refills,
                version: version,
                encounterID: encounterID,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered denial checkpoint in status new.
    static func newTieredDenialCheckpoint(_ code: String, label: String) -> TieredDenialCheckpoint {
        return TieredDenialCheckpoint(
            code: code,
            label: label,
            refills: 0,
            version: 0,
            encounterID: "",
            facility: "",
            status: TieredDenialCheckpointStatus.new
        )
    }
}
