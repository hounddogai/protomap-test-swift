import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched outreach checkpoint is in its life cycle.
    enum BatchedOutreachCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched outreach checkpoint as the outreach team keeps it.
    final class BatchedOutreachCheckpoint {
        var code: String
        var name: String
        var attempts: Int
        var rate: Double
        var maximum: Double
        var sequence: Int
        var ward: String
        var visible: Bool
        var ownerID: String
        var status: BatchedOutreachCheckpointStatus

        init(code: String, name: String, attempts: Int, rate: Double, maximum: Double, sequence: Int, ward: String, visible: Bool, ownerID: String, status: BatchedOutreachCheckpointStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.rate = rate
            self.maximum = maximum
            self.sequence = sequence
            self.ward = ward
            self.visible = visible
            self.ownerID = ownerID
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

        func canMoveTo(_ next: BatchedOutreachCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == BatchedOutreachCheckpointStatus.queued
            case .queued:
                return next == BatchedOutreachCheckpointStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedOutreachCheckpointStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOutreachCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched outreach checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return (rate * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOutreachCheckpoint {
            return BatchedOutreachCheckpoint(
                code: code,
                name: name,
                attempts: attempts,
                rate: rate,
                maximum: maximum,
                sequence: sequence,
                ward: ward,
                visible: visible,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched outreach checkpoint in status new.
    static func newBatchedOutreachCheckpoint(_ code: String, name: String) -> BatchedOutreachCheckpoint {
        return BatchedOutreachCheckpoint(
            code: code,
            name: name,
            attempts: 0,
            rate: 0.0,
            maximum: 0.0,
            sequence: 0,
            ward: "",
            visible: false,
            ownerID: "",
            status: BatchedOutreachCheckpointStatus.new
        )
    }
}
