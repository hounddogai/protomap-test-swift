import AcmePlatform
import Foundation

extension Consent {
    /// Where a default witness preference is in its life cycle.
    enum DefaultWitnessPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default witness preference. Its code is unique within a tenant.
    final class DefaultWitnessPreference {
        var code: String
        var name: String
        var version: Int
        var reviewer: String
        var ownerID: String
        var allergy: String
        var clinicianID: String
        var ward: String
        var attempts: Int
        var threshold: Double
        var refills: Int
        var status: DefaultWitnessPreferenceStatus

        init(code: String, name: String, version: Int, reviewer: String, ownerID: String, allergy: String, clinicianID: String, ward: String, attempts: Int, threshold: Double, refills: Int, status: DefaultWitnessPreferenceStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.ward = ward
            self.attempts = attempts
            self.threshold = threshold
            self.refills = refills
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

        func canMoveTo(_ next: DefaultWitnessPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultWitnessPreferenceStatus.published || next == DefaultWitnessPreferenceStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultWitnessPreferenceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultWitnessPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default witness preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return ((Double(refills) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultWitnessPreference {
            return DefaultWitnessPreference(
                code: code,
                name: name,
                version: version,
                reviewer: reviewer,
                ownerID: ownerID,
                allergy: allergy,
                clinicianID: clinicianID,
                ward: ward,
                attempts: attempts,
                threshold: threshold,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default witness preference in status created.
    static func newDefaultWitnessPreference(_ code: String, name: String) -> DefaultWitnessPreference {
        return DefaultWitnessPreference(
            code: code,
            name: name,
            version: 0,
            reviewer: "",
            ownerID: "",
            allergy: "",
            clinicianID: "",
            ward: "",
            attempts: 0,
            threshold: 0.0,
            refills: 0,
            status: DefaultWitnessPreferenceStatus.created
        )
    }
}
