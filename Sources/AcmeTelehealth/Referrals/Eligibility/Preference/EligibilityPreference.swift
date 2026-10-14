import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility preference is in its life cycle.
    enum EligibilityPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One eligibility preference, with what the planners need to act on it.
    final class EligibilityPreference {
        var code: String
        var name: String
        var minimum: Double
        var patientRef: String
        var batchSize: Int
        var ownerID: String
        var specialty: String
        var tags: [String]
        var contactEmail: String
        var status: EligibilityPreferenceStatus

        init(code: String, name: String, minimum: Double, patientRef: String, batchSize: Int, ownerID: String, specialty: String, tags: [String], contactEmail: String, status: EligibilityPreferenceStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.specialty = specialty
            self.tags = tags
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: EligibilityPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == EligibilityPreferenceStatus.inProgress || next == EligibilityPreferenceStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: EligibilityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return (minimum * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityPreference {
            return EligibilityPreference(
                code: code,
                name: name,
                minimum: minimum,
                patientRef: patientRef,
                batchSize: batchSize,
                ownerID: ownerID,
                specialty: specialty,
                tags: tags,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility preference in status planned.
    static func newEligibilityPreference(_ code: String, name: String) -> EligibilityPreference {
        return EligibilityPreference(
            code: code,
            name: name,
            minimum: 0.0,
            patientRef: "",
            batchSize: 0,
            ownerID: "",
            specialty: "",
            tags: [],
            contactEmail: "",
            status: EligibilityPreferenceStatus.planned
        )
    }
}
