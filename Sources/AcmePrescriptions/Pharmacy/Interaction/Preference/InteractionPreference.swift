import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction preference is in its life cycle.
    enum InteractionPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One interaction preference, with what the planners need to act on it.
    final class InteractionPreference {
        var code: String
        var label: String
        var discount: Double
        var diagnosisCode: String
        var region: String
        var allergy: String
        var checksum: String
        var tags: [String]
        var specialty: String
        var procedureCode: String
        var version: Int
        var status: InteractionPreferenceStatus

        init(code: String, label: String, discount: Double, diagnosisCode: String, region: String, allergy: String, checksum: String, tags: [String], specialty: String, procedureCode: String, version: Int, status: InteractionPreferenceStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.allergy = allergy
            self.checksum = checksum
            self.tags = tags
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.version = version
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

        func canMoveTo(_ next: InteractionPreferenceStatus) -> Bool {
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
                return next == InteractionPreferenceStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: InteractionPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (Double(version) * discount * 100).rounded() / 100
        }

        func copyValue() -> InteractionPreference {
            return InteractionPreference(
                code: code,
                label: label,
                discount: discount,
                diagnosisCode: diagnosisCode,
                region: region,
                allergy: allergy,
                checksum: checksum,
                tags: tags,
                specialty: specialty,
                procedureCode: procedureCode,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a interaction preference in status planned.
    static func newInteractionPreference(_ code: String, label: String) -> InteractionPreference {
        return InteractionPreference(
            code: code,
            label: label,
            discount: 0.0,
            diagnosisCode: "",
            region: "",
            allergy: "",
            checksum: "",
            tags: [],
            specialty: "",
            procedureCode: "",
            version: 0,
            status: InteractionPreferenceStatus.planned
        )
    }
}
