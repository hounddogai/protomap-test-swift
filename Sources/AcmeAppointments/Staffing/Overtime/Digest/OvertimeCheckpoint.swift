import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime checkpoint is in its life cycle.
    enum OvertimeCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One overtime checkpoint, with what the planners need to act on it.
    final class OvertimeCheckpoint {
        var code: String
        var label: String
        var updatedAt: Int
        var startsAt: Int
        var ceiling: Double
        var tags: [String]
        var payer: String
        var bed: String
        var status: OvertimeCheckpointStatus

        init(code: String, label: String, updatedAt: Int, startsAt: Int, ceiling: Double, tags: [String], payer: String, bed: String, status: OvertimeCheckpointStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.tags = tags
            self.payer = payer
            self.bed = bed
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

        func canMoveTo(_ next: OvertimeCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == OvertimeCheckpointStatus.warming || next == OvertimeCheckpointStatus.stopped
            case .warming:
                return next == OvertimeCheckpointStatus.ready || next == OvertimeCheckpointStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == OvertimeCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("overtime checkpoint") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((ceiling - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeCheckpoint {
            return OvertimeCheckpoint(
                code: code,
                label: label,
                updatedAt: updatedAt,
                startsAt: startsAt,
                ceiling: ceiling,
                tags: tags,
                payer: payer,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a overtime checkpoint in status idle.
    static func newOvertimeCheckpoint(_ code: String, label: String) -> OvertimeCheckpoint {
        return OvertimeCheckpoint(
            code: code,
            label: label,
            updatedAt: 0,
            startsAt: 0,
            ceiling: 0.0,
            tags: [],
            payer: "",
            bed: "",
            status: OvertimeCheckpointStatus.idle
        )
    }
}
