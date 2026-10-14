import AcmePlatform
import Foundation

extension Labs {
    /// Where a default specimen plan is in its life cycle.
    enum DefaultSpecimenPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default specimen plan. Its code is unique within a tenant.
    final class DefaultSpecimenPlan {
        var code: String
        var title: String
        var summary: String
        var margin: Double
        var minimum: Double
        var unit: String
        var specialty: String
        var status: DefaultSpecimenPlanStatus

        init(code: String, title: String, summary: String, margin: Double, minimum: Double, unit: String, specialty: String, status: DefaultSpecimenPlanStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.margin = margin
            self.minimum = minimum
            self.unit = unit
            self.specialty = specialty
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

        func canMoveTo(_ next: DefaultSpecimenPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultSpecimenPlanStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultSpecimenPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default specimen plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return ((margin + minimum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSpecimenPlan {
            return DefaultSpecimenPlan(
                code: code,
                title: title,
                summary: summary,
                margin: margin,
                minimum: minimum,
                unit: unit,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a default specimen plan in status proposed.
    static func newDefaultSpecimenPlan(_ code: String, title: String) -> DefaultSpecimenPlan {
        return DefaultSpecimenPlan(
            code: code,
            title: title,
            summary: "",
            margin: 0.0,
            minimum: 0.0,
            unit: "",
            specialty: "",
            status: DefaultSpecimenPlanStatus.proposed
        )
    }
}
