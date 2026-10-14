import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure claim is in its life cycle.
    enum ClosureClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One closure claim, with what the planners need to act on it.
    final class ClosureClaim {
        var code: String
        var name: String
        var ratio: Double
        var copay: Double
        var sequence: Int
        var status: ClosureClaimStatus

        init(code: String, name: String, ratio: Double, copay: Double, sequence: Int, status: ClosureClaimStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.copay = copay
            self.sequence = sequence
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

        func canMoveTo(_ next: ClosureClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ClosureClaimStatus.completed || next == ClosureClaimStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ClosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netLoad() -> Double {
            return ((copay - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ClosureClaim {
            return ClosureClaim(
                code: code,
                name: name,
                ratio: ratio,
                copay: copay,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a closure claim in status planned.
    static func newClosureClaim(_ code: String, name: String) -> ClosureClaim {
        return ClosureClaim(
            code: code,
            name: name,
            ratio: 0.0,
            copay: 0.0,
            sequence: 0,
            status: ClosureClaimStatus.planned
        )
    }
}
