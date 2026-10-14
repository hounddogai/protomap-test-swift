import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional overtime plan is in its life cycle.
    enum RegionalOvertimePlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional overtime plan as the overtime team keeps it.
    final class RegionalOvertimePlan {
        var code: String
        var name: String
        var weight: Double
        var procedureCode: String
        var externalRef: String
        var status: RegionalOvertimePlanStatus

        init(code: String, name: String, weight: Double, procedureCode: String, externalRef: String, status: RegionalOvertimePlanStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.procedureCode = procedureCode
            self.externalRef = externalRef
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

        func canMoveTo(_ next: RegionalOvertimePlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalOvertimePlanStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: RegionalOvertimePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional overtime plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> RegionalOvertimePlan {
            return RegionalOvertimePlan(
                code: code,
                name: name,
                weight: weight,
                procedureCode: procedureCode,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional overtime plan in status proposed.
    static func newRegionalOvertimePlan(_ code: String, name: String) -> RegionalOvertimePlan {
        return RegionalOvertimePlan(
            code: code,
            name: name,
            weight: 0.0,
            procedureCode: "",
            externalRef: "",
            status: RegionalOvertimePlanStatus.proposed
        )
    }
}
