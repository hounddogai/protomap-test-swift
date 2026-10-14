import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result agreement is in its life cycle.
    enum RollingResultAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling result agreement as the result team keeps it.
    final class RollingResultAgreement {
        var code: String
        var name: String
        var floorValue: Double
        var priority: Int
        var quantity: Int
        var capacity: Int
        var status: RollingResultAgreementStatus

        init(code: String, name: String, floorValue: Double, priority: Int, quantity: Int, capacity: Int, status: RollingResultAgreementStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.priority = priority
            self.quantity = quantity
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingResultAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingResultAgreementStatus.validated || next == RollingResultAgreementStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingResultAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingResultAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(priority) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RollingResultAgreement {
            return RollingResultAgreement(
                code: code,
                name: name,
                floorValue: floorValue,
                priority: priority,
                quantity: quantity,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling result agreement in status created.
    static func newRollingResultAgreement(_ code: String, name: String) -> RollingResultAgreement {
        return RollingResultAgreement(
            code: code,
            name: name,
            floorValue: 0.0,
            priority: 0,
            quantity: 0,
            capacity: 0,
            status: RollingResultAgreementStatus.created
        )
    }
}
