import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance allocation is in its life cycle.
    enum RemittanceAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a remittance allocation and its current status.
    final class RemittanceAllocation {
        var code: String
        var label: String
        var unit: String
        var active: Bool
        var floorValue: Double
        var priority: Int
        var ratio: Double
        var acuity: Int
        var status: RemittanceAllocationStatus

        init(code: String, label: String, unit: String, active: Bool, floorValue: Double, priority: Int, ratio: Double, acuity: Int, status: RemittanceAllocationStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.active = active
            self.floorValue = floorValue
            self.priority = priority
            self.ratio = ratio
            self.acuity = acuity
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

        func canMoveTo(_ next: RemittanceAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RemittanceAllocationStatus.draining || next == RemittanceAllocationStatus.stopped
            case .ready:
                return next == RemittanceAllocationStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RemittanceAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(acuity) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceAllocation {
            return RemittanceAllocation(
                code: code,
                label: label,
                unit: unit,
                active: active,
                floorValue: floorValue,
                priority: priority,
                ratio: ratio,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a remittance allocation in status idle.
    static func newRemittanceAllocation(_ code: String, label: String) -> RemittanceAllocation {
        return RemittanceAllocation(
            code: code,
            label: label,
            unit: "",
            active: false,
            floorValue: 0.0,
            priority: 0,
            ratio: 0.0,
            acuity: 0,
            status: RemittanceAllocationStatus.idle
        )
    }
}
