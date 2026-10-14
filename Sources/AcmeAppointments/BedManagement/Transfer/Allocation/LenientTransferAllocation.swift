import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient transfer allocation is in its life cycle.
    enum LenientTransferAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient transfer allocation as the transfer team keeps it.
    final class LenientTransferAllocation {
        var code: String
        var label: String
        var budget: Double
        var score: Double
        var createdAt: Int
        var status: LenientTransferAllocationStatus

        init(code: String, label: String, budget: Double, score: Double, createdAt: Int, status: LenientTransferAllocationStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.score = score
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientTransferAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientTransferAllocationStatus.approved || next == LenientTransferAllocationStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LenientTransferAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientTransferAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient transfer allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return (Double(createdAt) * score * 100).rounded() / 100
        }

        func copyValue() -> LenientTransferAllocation {
            return LenientTransferAllocation(
                code: code,
                label: label,
                budget: budget,
                score: score,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient transfer allocation in status proposed.
    static func newLenientTransferAllocation(_ code: String, label: String) -> LenientTransferAllocation {
        return LenientTransferAllocation(
            code: code,
            label: label,
            budget: 0.0,
            score: 0.0,
            createdAt: 0,
            status: LenientTransferAllocationStatus.proposed
        )
    }
}
