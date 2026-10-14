import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict specimen plan is in its life cycle.
    enum StrictSpecimenPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict specimen plan as the specimen team keeps it.
    final class StrictSpecimenPlan {
        var code: String
        var label: String
        var copay: Double
        var ceiling: Double
        var description: String
        var version: Int
        var status: StrictSpecimenPlanStatus

        init(code: String, label: String, copay: Double, ceiling: Double, description: String, version: Int, status: StrictSpecimenPlanStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.ceiling = ceiling
            self.description = description
            self.version = version
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

        func canMoveTo(_ next: StrictSpecimenPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictSpecimenPlanStatus.approved
            case .approved:
                return next == StrictSpecimenPlanStatus.rejected || next == StrictSpecimenPlanStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictSpecimenPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict specimen plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("strict specimen plan") \(code)"
        }

        func netExposure() -> Double {
            return (ceiling * copay * 100).rounded() / 100
        }

        func copyValue() -> StrictSpecimenPlan {
            return StrictSpecimenPlan(
                code: code,
                label: label,
                copay: copay,
                ceiling: ceiling,
                description: description,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict specimen plan in status proposed.
    static func newStrictSpecimenPlan(_ code: String, label: String) -> StrictSpecimenPlan {
        return StrictSpecimenPlan(
            code: code,
            label: label,
            copay: 0.0,
            ceiling: 0.0,
            description: "",
            version: 0,
            status: StrictSpecimenPlanStatus.proposed
        )
    }
}
