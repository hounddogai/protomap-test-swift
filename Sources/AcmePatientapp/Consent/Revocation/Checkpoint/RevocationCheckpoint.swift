import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation checkpoint is in its life cycle.
    enum RevocationCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One revocation checkpoint, with what the planners need to act on it.
    final class RevocationCheckpoint {
        var code: String
        var label: String
        var summary: String
        var batchSize: Int
        var quantity: Int
        var status: RevocationCheckpointStatus

        init(code: String, label: String, summary: String, batchSize: Int, quantity: Int, status: RevocationCheckpointStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.batchSize = batchSize
            self.quantity = quantity
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

        func canMoveTo(_ next: RevocationCheckpointStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: RevocationCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation checkpoint") \(code)"
        }

        func netValue() -> Double {
            return ((Double(quantity) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationCheckpoint {
            return RevocationCheckpoint(
                code: code,
                label: label,
                summary: summary,
                batchSize: batchSize,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation checkpoint in status new.
    static func newRevocationCheckpoint(_ code: String, label: String) -> RevocationCheckpoint {
        return RevocationCheckpoint(
            code: code,
            label: label,
            summary: "",
            batchSize: 0,
            quantity: 0,
            status: RevocationCheckpointStatus.new
        )
    }
}
