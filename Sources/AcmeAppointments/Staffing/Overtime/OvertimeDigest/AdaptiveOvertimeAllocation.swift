import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive overtime allocation is in its life cycle.
    enum AdaptiveOvertimeAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive overtime allocation and its current status.
    final class AdaptiveOvertimeAllocation {
        var code: String
        var name: String
        var ceiling: Double
        var graceDays: Int
        var dosageMg: Double
        var capacity: Int
        var phone: String
        var retries: Int
        var status: AdaptiveOvertimeAllocationStatus

        init(code: String, name: String, ceiling: Double, graceDays: Int, dosageMg: Double, capacity: Int, phone: String, retries: Int, status: AdaptiveOvertimeAllocationStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.graceDays = graceDays
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.phone = phone
            self.retries = retries
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

        func canMoveTo(_ next: AdaptiveOvertimeAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveOvertimeAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveOvertimeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive overtime allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((ceiling - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOvertimeAllocation {
            return AdaptiveOvertimeAllocation(
                code: code,
                name: name,
                ceiling: ceiling,
                graceDays: graceDays,
                dosageMg: dosageMg,
                capacity: capacity,
                phone: phone,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive overtime allocation in status proposed.
    static func newAdaptiveOvertimeAllocation(_ code: String, name: String) -> AdaptiveOvertimeAllocation {
        return AdaptiveOvertimeAllocation(
            code: code,
            name: name,
            ceiling: 0.0,
            graceDays: 0,
            dosageMg: 0.0,
            capacity: 0,
            phone: "",
            retries: 0,
            status: AdaptiveOvertimeAllocationStatus.proposed
        )
    }
}
