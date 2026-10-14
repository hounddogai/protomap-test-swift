import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled acuity plan allocation is in its life cycle.
    enum ScheduledAcuityPlanAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled acuity plan allocation and its current status.
    final class ScheduledAcuityPlanAllocation {
        var code: String
        var label: String
        var specialty: String
        var name: String
        var floorValue: Double
        var status: ScheduledAcuityPlanAllocationStatus

        init(code: String, label: String, specialty: String, name: String, floorValue: Double, status: ScheduledAcuityPlanAllocationStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.name = name
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledAcuityPlanAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledAcuityPlanAllocationStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledAcuityPlanAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled acuity plan allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ScheduledAcuityPlanAllocation {
            return ScheduledAcuityPlanAllocation(
                code: code,
                label: label,
                specialty: specialty,
                name: name,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled acuity plan allocation in status new.
    static func newScheduledAcuityPlanAllocation(_ code: String, label: String) -> ScheduledAcuityPlanAllocation {
        return ScheduledAcuityPlanAllocation(
            code: code,
            label: label,
            specialty: "",
            name: "",
            floorValue: 0.0,
            status: ScheduledAcuityPlanAllocationStatus.new
        )
    }
}
