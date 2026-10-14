import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance checkpoint is in its life cycle.
    enum TieredRemittanceCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a tiered remittance checkpoint and its current status.
    final class TieredRemittanceCheckpoint {
        var code: String
        var name: String
        var endsAt: Int
        var amount: Double
        var archived: Bool
        var updatedAt: Int
        var specialty: String
        var status: TieredRemittanceCheckpointStatus

        init(code: String, name: String, endsAt: Int, amount: Double, archived: Bool, updatedAt: Int, specialty: String, status: TieredRemittanceCheckpointStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.amount = amount
            self.archived = archived
            self.updatedAt = updatedAt
            self.specialty = specialty
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

        func canMoveTo(_ next: TieredRemittanceCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredRemittanceCheckpointStatus.completed
            case .scheduled:
                return next == TieredRemittanceCheckpointStatus.inProgress || next == TieredRemittanceCheckpointStatus.completed
            case .inProgress:
                return next == TieredRemittanceCheckpointStatus.cancelled
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

        func moveTo(_ next: TieredRemittanceCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered remittance checkpoint") \(code)"
        }

        func projectedTotal() -> Double {
            return ((amount - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceCheckpoint {
            return TieredRemittanceCheckpoint(
                code: code,
                name: name,
                endsAt: endsAt,
                amount: amount,
                archived: archived,
                updatedAt: updatedAt,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered remittance checkpoint in status planned.
    static func newTieredRemittanceCheckpoint(_ code: String, name: String) -> TieredRemittanceCheckpoint {
        return TieredRemittanceCheckpoint(
            code: code,
            name: name,
            endsAt: 0,
            amount: 0.0,
            archived: false,
            updatedAt: 0,
            specialty: "",
            status: TieredRemittanceCheckpointStatus.planned
        )
    }
}
