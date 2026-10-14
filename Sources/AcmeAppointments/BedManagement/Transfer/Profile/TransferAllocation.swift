import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer allocation is in its life cycle.
    enum TransferAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A transfer allocation as the transfer team keeps it.
    final class TransferAllocation {
        var code: String
        var name: String
        var margin: Double
        var durationMinutes: Int
        var approved: Bool
        var score: Double
        var quantity: Int
        var payer: String
        var status: TransferAllocationStatus

        init(code: String, name: String, margin: Double, durationMinutes: Int, approved: Bool, score: Double, quantity: Int, payer: String, status: TransferAllocationStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.score = score
            self.quantity = quantity
            self.payer = payer
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

        func canMoveTo(_ next: TransferAllocationStatus) -> Bool {
            switch status {
            case .idle:
                return next == TransferAllocationStatus.ready
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TransferAllocationStatus.draining || next == TransferAllocationStatus.stopped
            case .draining:
                return next == TransferAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((score + margin) * 100).rounded() / 100
        }

        func copyValue() -> TransferAllocation {
            return TransferAllocation(
                code: code,
                name: name,
                margin: margin,
                durationMinutes: durationMinutes,
                approved: approved,
                score: score,
                quantity: quantity,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer allocation in status idle.
    static func newTransferAllocation(_ code: String, name: String) -> TransferAllocation {
        return TransferAllocation(
            code: code,
            name: name,
            margin: 0.0,
            durationMinutes: 0,
            approved: false,
            score: 0.0,
            quantity: 0,
            payer: "",
            status: TransferAllocationStatus.idle
        )
    }
}
