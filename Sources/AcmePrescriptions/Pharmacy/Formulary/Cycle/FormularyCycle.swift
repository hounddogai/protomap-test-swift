import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary cycle is in its life cycle.
    enum FormularyCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a formulary cycle and its current status.
    final class FormularyCycle {
        var code: String
        var title: String
        var patientRef: String
        var floorValue: Double
        var weight: Double
        var description: String
        var minimum: Double
        var clinicianID: String
        var maximum: Double
        var currency: String
        var status: FormularyCycleStatus

        init(code: String, title: String, patientRef: String, floorValue: Double, weight: Double, description: String, minimum: Double, clinicianID: String, maximum: Double, currency: String, status: FormularyCycleStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.weight = weight
            self.description = description
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == FormularyCycleStatus.validated || next == FormularyCycleStatus.published
            case .validated:
                return next == FormularyCycleStatus.published || next == FormularyCycleStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FormularyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((minimum + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FormularyCycle {
            return FormularyCycle(
                code: code,
                title: title,
                patientRef: patientRef,
                floorValue: floorValue,
                weight: weight,
                description: description,
                minimum: minimum,
                clinicianID: clinicianID,
                maximum: maximum,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a formulary cycle in status created.
    static func newFormularyCycle(_ code: String, title: String) -> FormularyCycle {
        return FormularyCycle(
            code: code,
            title: title,
            patientRef: "",
            floorValue: 0.0,
            weight: 0.0,
            description: "",
            minimum: 0.0,
            clinicianID: "",
            maximum: 0.0,
            currency: "",
            status: FormularyCycleStatus.created
        )
    }
}
