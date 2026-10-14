import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall cycle is in its life cycle.
    enum RecallCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a recall cycle and its current status.
    final class RecallCycle {
        var code: String
        var title: String
        var pinned: Bool
        var segment: String
        var revision: Int
        var threshold: Double
        var capacity: Int
        var ceiling: Double
        var name: String
        var status: RecallCycleStatus

        init(code: String, title: String, pinned: Bool, segment: String, revision: Int, threshold: Double, capacity: Int, ceiling: Double, name: String, status: RecallCycleStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.segment = segment
            self.revision = revision
            self.threshold = threshold
            self.capacity = capacity
            self.ceiling = ceiling
            self.name = name
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

        func canMoveTo(_ next: RecallCycleStatus) -> Bool {
            switch status {
            case .requested:
                return next == RecallCycleStatus.revoked
            case .granted:
                return next == RecallCycleStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RecallCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("recall cycle") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(capacity) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RecallCycle {
            return RecallCycle(
                code: code,
                title: title,
                pinned: pinned,
                segment: segment,
                revision: revision,
                threshold: threshold,
                capacity: capacity,
                ceiling: ceiling,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a recall cycle in status requested.
    static func newRecallCycle(_ code: String, title: String) -> RecallCycle {
        return RecallCycle(
            code: code,
            title: title,
            pinned: false,
            segment: "",
            revision: 0,
            threshold: 0.0,
            capacity: 0,
            ceiling: 0.0,
            name: "",
            status: RecallCycleStatus.requested
        )
    }
}
