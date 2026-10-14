import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen variance is in its life cycle.
    enum SpecimenVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A specimen variance. Its code is unique within a tenant.
    final class SpecimenVariance {
        var code: String
        var title: String
        var bed: String
        var allergy: String
        var label: String
        var specialty: String
        var patientRef: String
        var attributes: [String: String]
        var margin: Double
        var status: SpecimenVarianceStatus

        init(code: String, title: String, bed: String, allergy: String, label: String, specialty: String, patientRef: String, attributes: [String: String], margin: Double, status: SpecimenVarianceStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.allergy = allergy
            self.label = label
            self.specialty = specialty
            self.patientRef = patientRef
            self.attributes = attributes
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenVarianceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SpecimenVarianceStatus.active || next == SpecimenVarianceStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SpecimenVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> SpecimenVariance {
            return SpecimenVariance(
                code: code,
                title: title,
                bed: bed,
                allergy: allergy,
                label: label,
                specialty: specialty,
                patientRef: patientRef,
                attributes: attributes,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen variance in status draft.
    static func newSpecimenVariance(_ code: String, title: String) -> SpecimenVariance {
        return SpecimenVariance(
            code: code,
            title: title,
            bed: "",
            allergy: "",
            label: "",
            specialty: "",
            patientRef: "",
            attributes: [:],
            margin: 0.0,
            status: SpecimenVarianceStatus.draft
        )
    }
}
