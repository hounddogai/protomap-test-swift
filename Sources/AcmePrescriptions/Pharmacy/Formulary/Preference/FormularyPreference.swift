import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary preference is in its life cycle.
    enum FormularyPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a formulary preference and its current status.
    final class FormularyPreference {
        var code: String
        var name: String
        var externalRef: String
        var unit: String
        var budget: Double
        var notes: String
        var locale: String
        var category: String
        var status: FormularyPreferenceStatus

        init(code: String, name: String, externalRef: String, unit: String, budget: Double, notes: String, locale: String, category: String, status: FormularyPreferenceStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.unit = unit
            self.budget = budget
            self.notes = notes
            self.locale = locale
            self.category = category
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

        func canMoveTo(_ next: FormularyPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
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
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FormularyPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("formulary preference") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> FormularyPreference {
            return FormularyPreference(
                code: code,
                name: name,
                externalRef: externalRef,
                unit: unit,
                budget: budget,
                notes: notes,
                locale: locale,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a formulary preference in status planned.
    static func newFormularyPreference(_ code: String, name: String) -> FormularyPreference {
        return FormularyPreference(
            code: code,
            name: name,
            externalRef: "",
            unit: "",
            budget: 0.0,
            notes: "",
            locale: "",
            category: "",
            status: FormularyPreferenceStatus.planned
        )
    }
}
