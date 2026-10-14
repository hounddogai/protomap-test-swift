import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen budget is in its life cycle.
    enum SpecimenBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a specimen budget and its current status.
    final class SpecimenBudget {
        var code: String
        var label: String
        var weight: Double
        var patientRef: String
        var ward: String
        var cost: Double
        var floorValue: Double
        var ratio: Double
        var timezone: String
        var status: SpecimenBudgetStatus

        init(code: String, label: String, weight: Double, patientRef: String, ward: String, cost: Double, floorValue: Double, ratio: Double, timezone: String, status: SpecimenBudgetStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.patientRef = patientRef
            self.ward = ward
            self.cost = cost
            self.floorValue = floorValue
            self.ratio = ratio
            self.timezone = timezone
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

        func canMoveTo(_ next: SpecimenBudgetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SpecimenBudgetStatus.ready || next == SpecimenBudgetStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SpecimenBudgetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("specimen budget") \(code)"
        }

        func effectiveValue() -> Double {
            return (ratio * weight * 100).rounded() / 100
        }

        func copyValue() -> SpecimenBudget {
            return SpecimenBudget(
                code: code,
                label: label,
                weight: weight,
                patientRef: patientRef,
                ward: ward,
                cost: cost,
                floorValue: floorValue,
                ratio: ratio,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a specimen budget in status idle.
    static func newSpecimenBudget(_ code: String, label: String) -> SpecimenBudget {
        return SpecimenBudget(
            code: code,
            label: label,
            weight: 0.0,
            patientRef: "",
            ward: "",
            cost: 0.0,
            floorValue: 0.0,
            ratio: 0.0,
            timezone: "",
            status: SpecimenBudgetStatus.idle
        )
    }
}
