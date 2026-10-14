import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default float pool request is in its life cycle.
    enum DefaultFloatPoolRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default float pool request as the float pool team keeps it.
    final class DefaultFloatPoolRequest {
        var code: String
        var name: String
        var visible: Bool
        var region: String
        var budget: Double
        var specialty: String
        var status: DefaultFloatPoolRequestStatus

        init(code: String, name: String, visible: Bool, region: String, budget: Double, specialty: String, status: DefaultFloatPoolRequestStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.region = region
            self.budget = budget
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

        func canMoveTo(_ next: DefaultFloatPoolRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DefaultFloatPoolRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default float pool request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> DefaultFloatPoolRequest {
            return DefaultFloatPoolRequest(
                code: code,
                name: name,
                visible: visible,
                region: region,
                budget: budget,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default float pool request in status proposed.
    static func newDefaultFloatPoolRequest(_ code: String, name: String) -> DefaultFloatPoolRequest {
        return DefaultFloatPoolRequest(
            code: code,
            name: name,
            visible: false,
            region: "",
            budget: 0.0,
            specialty: "",
            status: DefaultFloatPoolRequestStatus.proposed
        )
    }
}
