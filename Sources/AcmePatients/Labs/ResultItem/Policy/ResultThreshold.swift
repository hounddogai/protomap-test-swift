import AcmePlatform
import Foundation

extension Labs {
    /// Where a result threshold is in its life cycle.
    enum ResultThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a result threshold and its current status.
    final class ResultThreshold {
        var code: String
        var label: String
        var facility: String
        var procedureCode: String
        var ward: String
        var active: Bool
        var minimum: Double
        var windowDays: Int
        var budget: Double
        var status: ResultThresholdStatus

        init(code: String, label: String, facility: String, procedureCode: String, ward: String, active: Bool, minimum: Double, windowDays: Int, budget: Double, status: ResultThresholdStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.procedureCode = procedureCode
            self.ward = ward
            self.active = active
            self.minimum = minimum
            self.windowDays = windowDays
            self.budget = budget
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

        func canMoveTo(_ next: ResultThresholdStatus) -> Bool {
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

        func moveTo(_ next: ResultThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return (minimum * budget * 100).rounded() / 100
        }

        func copyValue() -> ResultThreshold {
            return ResultThreshold(
                code: code,
                label: label,
                facility: facility,
                procedureCode: procedureCode,
                ward: ward,
                active: active,
                minimum: minimum,
                windowDays: windowDays,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a result threshold in status proposed.
    static func newResultThreshold(_ code: String, label: String) -> ResultThreshold {
        return ResultThreshold(
            code: code,
            label: label,
            facility: "",
            procedureCode: "",
            ward: "",
            active: false,
            minimum: 0.0,
            windowDays: 0,
            budget: 0.0,
            status: ResultThresholdStatus.proposed
        )
    }
}
