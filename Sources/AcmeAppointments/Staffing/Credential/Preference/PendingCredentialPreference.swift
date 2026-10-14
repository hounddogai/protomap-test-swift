import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending credential preference is in its life cycle.
    enum PendingCredentialPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending credential preference, with what the planners need to act on it.
    final class PendingCredentialPreference {
        var code: String
        var name: String
        var sequence: Int
        var acuity: Int
        var specialty: String
        var pinned: Bool
        var cost: Double
        var label: String
        var revision: Int
        var contactEmail: String
        var segment: String
        var status: PendingCredentialPreferenceStatus

        init(code: String, name: String, sequence: Int, acuity: Int, specialty: String, pinned: Bool, cost: Double, label: String, revision: Int, contactEmail: String, segment: String, status: PendingCredentialPreferenceStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.acuity = acuity
            self.specialty = specialty
            self.pinned = pinned
            self.cost = cost
            self.label = label
            self.revision = revision
            self.contactEmail = contactEmail
            self.segment = segment
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

        func canMoveTo(_ next: PendingCredentialPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PendingCredentialPreferenceStatus.expired
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

        func moveTo(_ next: PendingCredentialPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending credential preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return ((cost + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCredentialPreference {
            return PendingCredentialPreference(
                code: code,
                name: name,
                sequence: sequence,
                acuity: acuity,
                specialty: specialty,
                pinned: pinned,
                cost: cost,
                label: label,
                revision: revision,
                contactEmail: contactEmail,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending credential preference in status requested.
    static func newPendingCredentialPreference(_ code: String, name: String) -> PendingCredentialPreference {
        return PendingCredentialPreference(
            code: code,
            name: name,
            sequence: 0,
            acuity: 0,
            specialty: "",
            pinned: false,
            cost: 0.0,
            label: "",
            revision: 0,
            contactEmail: "",
            segment: "",
            status: PendingCredentialPreferenceStatus.requested
        )
    }
}
