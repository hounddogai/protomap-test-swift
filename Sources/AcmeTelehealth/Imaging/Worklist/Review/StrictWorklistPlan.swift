import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict worklist plan is in its life cycle.
    enum StrictWorklistPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict worklist plan as the worklist team keeps it.
    final class StrictWorklistPlan {
        var code: String
        var title: String
        var cost: Double
        var ward: String
        var priority: Int
        var visible: Bool
        var floorValue: Double
        var label: String
        var bed: String
        var status: StrictWorklistPlanStatus

        init(code: String, title: String, cost: Double, ward: String, priority: Int, visible: Bool, floorValue: Double, label: String, bed: String, status: StrictWorklistPlanStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.ward = ward
            self.priority = priority
            self.visible = visible
            self.floorValue = floorValue
            self.label = label
            self.bed = bed
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

        func canMoveTo(_ next: StrictWorklistPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StrictWorklistPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictWorklistPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict worklist plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return (floorValue * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> StrictWorklistPlan {
            return StrictWorklistPlan(
                code: code,
                title: title,
                cost: cost,
                ward: ward,
                priority: priority,
                visible: visible,
                floorValue: floorValue,
                label: label,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict worklist plan in status new.
    static func newStrictWorklistPlan(_ code: String, title: String) -> StrictWorklistPlan {
        return StrictWorklistPlan(
            code: code,
            title: title,
            cost: 0.0,
            ward: "",
            priority: 0,
            visible: false,
            floorValue: 0.0,
            label: "",
            bed: "",
            status: StrictWorklistPlanStatus.new
        )
    }
}
