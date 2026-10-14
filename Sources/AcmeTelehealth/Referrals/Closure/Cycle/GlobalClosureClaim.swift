import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global closure claim is in its life cycle.
    enum GlobalClosureClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global closure claim, with what the planners need to act on it.
    final class GlobalClosureClaim {
        var code: String
        var title: String
        var ward: String
        var ownerID: String
        var encounterID: String
        var country: String
        var endsAt: Int
        var status: GlobalClosureClaimStatus

        init(code: String, title: String, ward: String, ownerID: String, encounterID: String, country: String, endsAt: Int, status: GlobalClosureClaimStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.country = country
            self.endsAt = endsAt
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

        func canMoveTo(_ next: GlobalClosureClaimStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalClosureClaimStatus.published || next == GlobalClosureClaimStatus.retired
            case .validated:
                return next == GlobalClosureClaimStatus.published || next == GlobalClosureClaimStatus.retired
            case .published:
                return next == GlobalClosureClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalClosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global closure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> GlobalClosureClaim {
            return GlobalClosureClaim(
                code: code,
                title: title,
                ward: ward,
                ownerID: ownerID,
                encounterID: encounterID,
                country: country,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global closure claim in status created.
    static func newGlobalClosureClaim(_ code: String, title: String) -> GlobalClosureClaim {
        return GlobalClosureClaim(
            code: code,
            title: title,
            ward: "",
            ownerID: "",
            encounterID: "",
            country: "",
            endsAt: 0,
            status: GlobalClosureClaimStatus.created
        )
    }
}
