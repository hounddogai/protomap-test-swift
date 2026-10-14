import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary recall plan is in its life cycle.
    enum PrimaryRecallPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary recall plan as the recall team keeps it.
    final class PrimaryRecallPlan {
        var code: String
        var label: String
        var priority: Int
        var region: String
        var dosageMg: Double
        var createdAt: Int
        var status: PrimaryRecallPlanStatus

        init(code: String, label: String, priority: Int, region: String, dosageMg: Double, createdAt: Int, status: PrimaryRecallPlanStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.region = region
            self.dosageMg = dosageMg
            self.createdAt = createdAt
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

        func canMoveTo(_ next: PrimaryRecallPlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryRecallPlanStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PrimaryRecallPlanStatus.completed || next == PrimaryRecallPlanStatus.cancelled
            case .completed:
                return next == PrimaryRecallPlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRecallPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary recall plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((dosageMg - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRecallPlan {
            return PrimaryRecallPlan(
                code: code,
                label: label,
                priority: priority,
                region: region,
                dosageMg: dosageMg,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary recall plan in status planned.
    static func newPrimaryRecallPlan(_ code: String, label: String) -> PrimaryRecallPlan {
        return PrimaryRecallPlan(
            code: code,
            label: label,
            priority: 0,
            region: "",
            dosageMg: 0.0,
            createdAt: 0,
            status: PrimaryRecallPlanStatus.planned
        )
    }
}
