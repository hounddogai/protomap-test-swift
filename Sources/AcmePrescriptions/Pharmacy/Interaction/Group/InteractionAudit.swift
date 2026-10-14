import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction audit is in its life cycle.
    enum InteractionAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A interaction audit as the interaction team keeps it.
    final class InteractionAudit {
        var code: String
        var name: String
        var label: String
        var sequence: Int
        var amount: Double
        var score: Double
        var status: InteractionAuditStatus

        init(code: String, name: String, label: String, sequence: Int, amount: Double, score: Double, status: InteractionAuditStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.sequence = sequence
            self.amount = amount
            self.score = score
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

        func canMoveTo(_ next: InteractionAuditStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == InteractionAuditStatus.completed || next == InteractionAuditStatus.cancelled
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

        func moveTo(_ next: InteractionAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return (amount * score * 100).rounded() / 100
        }

        func copyValue() -> InteractionAudit {
            return InteractionAudit(
                code: code,
                name: name,
                label: label,
                sequence: sequence,
                amount: amount,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction audit in status planned.
    static func newInteractionAudit(_ code: String, name: String) -> InteractionAudit {
        return InteractionAudit(
            code: code,
            name: name,
            label: "",
            sequence: 0,
            amount: 0.0,
            score: 0.0,
            status: InteractionAuditStatus.planned
        )
    }
}
