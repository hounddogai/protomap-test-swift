import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim bundle is in its life cycle.
    enum ClaimBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One claim bundle, with what the planners need to act on it.
    final class ClaimBundle {
        var code: String
        var title: String
        var limit: Int
        var ownerID: String
        var clinicianID: String
        var archived: Bool
        var payer: String
        var label: String
        var status: ClaimBundleStatus

        init(code: String, title: String, limit: Int, ownerID: String, clinicianID: String, archived: Bool, payer: String, label: String, status: ClaimBundleStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.archived = archived
            self.payer = payer
            self.label = label
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

        func canMoveTo(_ next: ClaimBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClaimBundleStatus.granted
            case .granted:
                return next == ClaimBundleStatus.revoked
            case .revoked:
                return next == ClaimBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> ClaimBundle {
            return ClaimBundle(
                code: code,
                title: title,
                limit: limit,
                ownerID: ownerID,
                clinicianID: clinicianID,
                archived: archived,
                payer: payer,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a claim bundle in status requested.
    static func newClaimBundle(_ code: String, title: String) -> ClaimBundle {
        return ClaimBundle(
            code: code,
            title: title,
            limit: 0,
            ownerID: "",
            clinicianID: "",
            archived: false,
            payer: "",
            label: "",
            status: ClaimBundleStatus.requested
        )
    }
}
