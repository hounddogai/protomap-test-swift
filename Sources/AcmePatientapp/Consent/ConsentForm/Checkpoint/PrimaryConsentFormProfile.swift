import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form profile is in its life cycle.
    enum PrimaryConsentFormProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary consent form profile, with what the planners need to act on it.
    final class PrimaryConsentFormProfile {
        var code: String
        var title: String
        var segment: String
        var specialty: String
        var category: String
        var retries: Int
        var status: PrimaryConsentFormProfileStatus

        init(code: String, title: String, segment: String, specialty: String, category: String, retries: Int, status: PrimaryConsentFormProfileStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.specialty = specialty
            self.category = category
            self.retries = retries
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

        func canMoveTo(_ next: PrimaryConsentFormProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryConsentFormProfileStatus.revoked
            case .granted:
                return next == PrimaryConsentFormProfileStatus.expired
            case .revoked:
                return next == PrimaryConsentFormProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryConsentFormProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> PrimaryConsentFormProfile {
            return PrimaryConsentFormProfile(
                code: code,
                title: title,
                segment: segment,
                specialty: specialty,
                category: category,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary consent form profile in status requested.
    static func newPrimaryConsentFormProfile(_ code: String, title: String) -> PrimaryConsentFormProfile {
        return PrimaryConsentFormProfile(
            code: code,
            title: title,
            segment: "",
            specialty: "",
            category: "",
            retries: 0,
            status: PrimaryConsentFormProfileStatus.requested
        )
    }
}
