import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen preference is in its life cycle.
    enum SpecimenPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a specimen preference and its current status.
    final class SpecimenPreference {
        var code: String
        var label: String
        var ceiling: Double
        var encounterID: String
        var archived: Bool
        var specialty: String
        var status: SpecimenPreferenceStatus

        init(code: String, label: String, ceiling: Double, encounterID: String, archived: Bool, specialty: String, status: SpecimenPreferenceStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.archived = archived
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == SpecimenPreferenceStatus.granted || next == SpecimenPreferenceStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: SpecimenPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> SpecimenPreference {
            return SpecimenPreference(
                code: code,
                label: label,
                ceiling: ceiling,
                encounterID: encounterID,
                archived: archived,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a specimen preference in status requested.
    static func newSpecimenPreference(_ code: String, label: String) -> SpecimenPreference {
        return SpecimenPreference(
            code: code,
            label: label,
            ceiling: 0.0,
            encounterID: "",
            archived: false,
            specialty: "",
            status: SpecimenPreferenceStatus.requested
        )
    }
}
