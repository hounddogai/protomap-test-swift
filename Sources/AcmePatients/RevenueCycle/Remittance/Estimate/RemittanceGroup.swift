import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance group is in its life cycle.
    enum RemittanceGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A remittance group. Its code is unique within a tenant.
    final class RemittanceGroup {
        var code: String
        var name: String
        var ceiling: Double
        var capacity: Int
        var minimum: Double
        var archived: Bool
        var amount: Double
        var payer: String
        var durationMinutes: Int
        var status: RemittanceGroupStatus

        init(code: String, name: String, ceiling: Double, capacity: Int, minimum: Double, archived: Bool, amount: Double, payer: String, durationMinutes: Int, status: RemittanceGroupStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.capacity = capacity
            self.minimum = minimum
            self.archived = archived
            self.amount = amount
            self.payer = payer
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: RemittanceGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == RemittanceGroupStatus.completed || next == RemittanceGroupStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RemittanceGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return (ceiling * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceGroup {
            return RemittanceGroup(
                code: code,
                name: name,
                ceiling: ceiling,
                capacity: capacity,
                minimum: minimum,
                archived: archived,
                amount: amount,
                payer: payer,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance group in status planned.
    static func newRemittanceGroup(_ code: String, name: String) -> RemittanceGroup {
        return RemittanceGroup(
            code: code,
            name: name,
            ceiling: 0.0,
            capacity: 0,
            minimum: 0.0,
            archived: false,
            amount: 0.0,
            payer: "",
            durationMinutes: 0,
            status: RemittanceGroupStatus.planned
        )
    }
}
