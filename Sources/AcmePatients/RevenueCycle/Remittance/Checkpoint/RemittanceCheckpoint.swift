import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance checkpoint is in its life cycle.
    enum RemittanceCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One remittance checkpoint, with what the planners need to act on it.
    final class RemittanceCheckpoint {
        var code: String
        var label: String
        var attempts: Int
        var startsAt: Int
        var category: String
        var ratio: Double
        var status: RemittanceCheckpointStatus

        init(code: String, label: String, attempts: Int, startsAt: Int, category: String, ratio: Double, status: RemittanceCheckpointStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.startsAt = startsAt
            self.category = category
            self.ratio = ratio
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

        func canMoveTo(_ next: RemittanceCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RemittanceCheckpointStatus.draining || next == RemittanceCheckpointStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RemittanceCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return ((ratio + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceCheckpoint {
            return RemittanceCheckpoint(
                code: code,
                label: label,
                attempts: attempts,
                startsAt: startsAt,
                category: category,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a remittance checkpoint in status idle.
    static func newRemittanceCheckpoint(_ code: String, label: String) -> RemittanceCheckpoint {
        return RemittanceCheckpoint(
            code: code,
            label: label,
            attempts: 0,
            startsAt: 0,
            category: "",
            ratio: 0.0,
            status: RemittanceCheckpointStatus.idle
        )
    }
}
