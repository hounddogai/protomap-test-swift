import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling charge record is in its life cycle.
    enum RollingChargeRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling charge record. Its code is unique within a tenant.
    final class RollingChargeRecord {
        var code: String
        var name: String
        var active: Bool
        var amount: Double
        var maximum: Double
        var status: RollingChargeRecordStatus

        init(code: String, name: String, active: Bool, amount: Double, maximum: Double, status: RollingChargeRecordStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.amount = amount
            self.maximum = maximum
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

        func canMoveTo(_ next: RollingChargeRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RollingChargeRecordStatus.stopped
            case .draining:
                return next == RollingChargeRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingChargeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling charge record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return (maximum * amount * 100).rounded() / 100
        }

        func copyValue() -> RollingChargeRecord {
            return RollingChargeRecord(
                code: code,
                name: name,
                active: active,
                amount: amount,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling charge record in status idle.
    static func newRollingChargeRecord(_ code: String, name: String) -> RollingChargeRecord {
        return RollingChargeRecord(
            code: code,
            name: name,
            active: false,
            amount: 0.0,
            maximum: 0.0,
            status: RollingChargeRecordStatus.idle
        )
    }
}
