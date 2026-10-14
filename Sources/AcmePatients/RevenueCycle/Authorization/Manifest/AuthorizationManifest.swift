import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization manifest is in its life cycle.
    enum AuthorizationManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a authorization manifest and its current status.
    final class AuthorizationManifest {
        var code: String
        var label: String
        var clinicianID: String
        var archived: Bool
        var active: Bool
        var contactEmail: String
        var durationMinutes: Int
        var amount: Double
        var status: AuthorizationManifestStatus

        init(code: String, label: String, clinicianID: String, archived: Bool, active: Bool, contactEmail: String, durationMinutes: Int, amount: Double, status: AuthorizationManifestStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.archived = archived
            self.active = active
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AuthorizationManifestStatus.reopened || next == AuthorizationManifestStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AuthorizationManifestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AuthorizationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("authorization manifest") \(code)"
        }

        func weightedVolume() -> Double {
            return (Double(durationMinutes) * amount * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationManifest {
            return AuthorizationManifest(
                code: code,
                label: label,
                clinicianID: clinicianID,
                archived: archived,
                active: active,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization manifest in status open.
    static func newAuthorizationManifest(_ code: String, label: String) -> AuthorizationManifest {
        return AuthorizationManifest(
            code: code,
            label: label,
            clinicianID: "",
            archived: false,
            active: false,
            contactEmail: "",
            durationMinutes: 0,
            amount: 0.0,
            status: AuthorizationManifestStatus.`open`
        )
    }
}
