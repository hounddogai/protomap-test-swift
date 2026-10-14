import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched recall profile is in its life cycle.
    enum BatchedRecallProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched recall profile, with what the planners need to act on it.
    final class BatchedRecallProfile {
        var code: String
        var label: String
        var sequence: Int
        var durationMinutes: Int
        var pinned: Bool
        var floorValue: Double
        var description: String
        var startsAt: Int
        var category: String
        var status: BatchedRecallProfileStatus

        init(code: String, label: String, sequence: Int, durationMinutes: Int, pinned: Bool, floorValue: Double, description: String, startsAt: Int, category: String, status: BatchedRecallProfileStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.floorValue = floorValue
            self.description = description
            self.startsAt = startsAt
            self.category = category
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

        func canMoveTo(_ next: BatchedRecallProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedRecallProfileStatus.ready
            case .warming:
                return next == BatchedRecallProfileStatus.ready || next == BatchedRecallProfileStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedRecallProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRecallProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched recall profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(sequence) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedRecallProfile {
            return BatchedRecallProfile(
                code: code,
                label: label,
                sequence: sequence,
                durationMinutes: durationMinutes,
                pinned: pinned,
                floorValue: floorValue,
                description: description,
                startsAt: startsAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched recall profile in status idle.
    static func newBatchedRecallProfile(_ code: String, label: String) -> BatchedRecallProfile {
        return BatchedRecallProfile(
            code: code,
            label: label,
            sequence: 0,
            durationMinutes: 0,
            pinned: false,
            floorValue: 0.0,
            description: "",
            startsAt: 0,
            category: "",
            status: BatchedRecallProfileStatus.idle
        )
    }
}
