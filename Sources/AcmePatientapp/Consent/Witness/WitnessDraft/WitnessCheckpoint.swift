import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness checkpoint is in its life cycle.
    enum WitnessCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness checkpoint as the witness team keeps it.
    final class WitnessCheckpoint {
        var code: String
        var title: String
        var procedureCode: String
        var maximum: Double
        var version: Int
        var pinned: Bool
        var status: WitnessCheckpointStatus

        init(code: String, title: String, procedureCode: String, maximum: Double, version: Int, pinned: Bool, status: WitnessCheckpointStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.version = version
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessCheckpointStatus.ready
            case .warming:
                return next == WitnessCheckpointStatus.stopped
            case .ready:
                return next == WitnessCheckpointStatus.draining
            case .draining:
                return next == WitnessCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("witness checkpoint") \(code)"
        }

        func weightedVolume() -> Double {
            return ((maximum + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessCheckpoint {
            return WitnessCheckpoint(
                code: code,
                title: title,
                procedureCode: procedureCode,
                maximum: maximum,
                version: version,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness checkpoint in status idle.
    static func newWitnessCheckpoint(_ code: String, title: String) -> WitnessCheckpoint {
        return WitnessCheckpoint(
            code: code,
            title: title,
            procedureCode: "",
            maximum: 0.0,
            version: 0,
            pinned: false,
            status: WitnessCheckpointStatus.idle
        )
    }
}
