import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling recall plan is in its life cycle.
    enum RollingRecallPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling recall plan as the recall team keeps it.
    final class RollingRecallPlan {
        var code: String
        var name: String
        var updatedAt: Int
        var dosageMg: Double
        var expiresAt: Int
        var status: RollingRecallPlanStatus

        init(code: String, name: String, updatedAt: Int, dosageMg: Double, expiresAt: Int, status: RollingRecallPlanStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RollingRecallPlanStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RollingRecallPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling recall plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return (dosageMg * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingRecallPlan {
            return RollingRecallPlan(
                code: code,
                name: name,
                updatedAt: updatedAt,
                dosageMg: dosageMg,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling recall plan in status planned.
    static func newRollingRecallPlan(_ code: String, name: String) -> RollingRecallPlan {
        return RollingRecallPlan(
            code: code,
            name: name,
            updatedAt: 0,
            dosageMg: 0.0,
            expiresAt: 0,
            status: RollingRecallPlanStatus.planned
        )
    }
}
