import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient accession checkpoint is in its life cycle.
    enum LenientAccessionCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One lenient accession checkpoint, with what the planners need to act on it.
    final class LenientAccessionCheckpoint {
        var code: String
        var name: String
        var channel: String
        var floorValue: Double
        var expiresAt: Int
        var currency: String
        var ratio: Double
        var status: LenientAccessionCheckpointStatus

        init(code: String, name: String, channel: String, floorValue: Double, expiresAt: Int, currency: String, ratio: Double, status: LenientAccessionCheckpointStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.currency = currency
            self.ratio = ratio
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

        func canMoveTo(_ next: LenientAccessionCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientAccessionCheckpointStatus.scheduled || next == LenientAccessionCheckpointStatus.inProgress
            case .scheduled:
                return next == LenientAccessionCheckpointStatus.completed || next == LenientAccessionCheckpointStatus.cancelled
            case .inProgress:
                return next == LenientAccessionCheckpointStatus.completed || next == LenientAccessionCheckpointStatus.cancelled
            case .completed:
                return next == LenientAccessionCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientAccessionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient accession checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return ((ratio - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LenientAccessionCheckpoint {
            return LenientAccessionCheckpoint(
                code: code,
                name: name,
                channel: channel,
                floorValue: floorValue,
                expiresAt: expiresAt,
                currency: currency,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient accession checkpoint in status planned.
    static func newLenientAccessionCheckpoint(_ code: String, name: String) -> LenientAccessionCheckpoint {
        return LenientAccessionCheckpoint(
            code: code,
            name: name,
            channel: "",
            floorValue: 0.0,
            expiresAt: 0,
            currency: "",
            ratio: 0.0,
            status: LenientAccessionCheckpointStatus.planned
        )
    }
}
