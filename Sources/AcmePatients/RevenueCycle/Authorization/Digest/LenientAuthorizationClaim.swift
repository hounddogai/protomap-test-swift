import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient authorization claim is in its life cycle.
    enum LenientAuthorizationClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient authorization claim as the authorization team keeps it.
    final class LenientAuthorizationClaim {
        var code: String
        var label: String
        var retries: Int
        var refills: Int
        var visible: Bool
        var endsAt: Int
        var approved: Bool
        var encounterID: String
        var specialty: String
        var source: String
        var status: LenientAuthorizationClaimStatus

        init(code: String, label: String, retries: Int, refills: Int, visible: Bool, endsAt: Int, approved: Bool, encounterID: String, specialty: String, source: String, status: LenientAuthorizationClaimStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.refills = refills
            self.visible = visible
            self.endsAt = endsAt
            self.approved = approved
            self.encounterID = encounterID
            self.specialty = specialty
            self.source = source
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

        func canMoveTo(_ next: LenientAuthorizationClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientAuthorizationClaimStatus.suspended
            case .pending:
                return next == LenientAuthorizationClaimStatus.suspended || next == LenientAuthorizationClaimStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: LenientAuthorizationClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient authorization claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return ((Double(refills) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> LenientAuthorizationClaim {
            return LenientAuthorizationClaim(
                code: code,
                label: label,
                retries: retries,
                refills: refills,
                visible: visible,
                endsAt: endsAt,
                approved: approved,
                encounterID: encounterID,
                specialty: specialty,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient authorization claim in status draft.
    static func newLenientAuthorizationClaim(_ code: String, label: String) -> LenientAuthorizationClaim {
        return LenientAuthorizationClaim(
            code: code,
            label: label,
            retries: 0,
            refills: 0,
            visible: false,
            endsAt: 0,
            approved: false,
            encounterID: "",
            specialty: "",
            source: "",
            status: LenientAuthorizationClaimStatus.draft
        )
    }
}
