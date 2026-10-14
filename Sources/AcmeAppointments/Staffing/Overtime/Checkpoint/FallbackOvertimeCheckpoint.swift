import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback overtime checkpoint is in its life cycle.
    enum FallbackOvertimeCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback overtime checkpoint. Its code is unique within a tenant.
    final class FallbackOvertimeCheckpoint {
        var code: String
        var title: String
        var label: String
        var clinicianID: String
        var pinned: Bool
        var score: Double
        var status: FallbackOvertimeCheckpointStatus

        init(code: String, title: String, label: String, clinicianID: String, pinned: Bool, score: Double, status: FallbackOvertimeCheckpointStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.score = score
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

        func canMoveTo(_ next: FallbackOvertimeCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackOvertimeCheckpointStatus.ready || next == FallbackOvertimeCheckpointStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackOvertimeCheckpointStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackOvertimeCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback overtime checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> FallbackOvertimeCheckpoint {
            return FallbackOvertimeCheckpoint(
                code: code,
                title: title,
                label: label,
                clinicianID: clinicianID,
                pinned: pinned,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback overtime checkpoint in status idle.
    static func newFallbackOvertimeCheckpoint(_ code: String, title: String) -> FallbackOvertimeCheckpoint {
        return FallbackOvertimeCheckpoint(
            code: code,
            title: title,
            label: "",
            clinicianID: "",
            pinned: false,
            score: 0.0,
            status: FallbackOvertimeCheckpointStatus.idle
        )
    }
}
