import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict census digest is in its life cycle.
    enum StrictCensusDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict census digest. Its code is unique within a tenant.
    final class StrictCensusDigest {
        var code: String
        var title: String
        var ownerID: String
        var reviewer: String
        var description: String
        var quantity: Int
        var status: StrictCensusDigestStatus

        init(code: String, title: String, ownerID: String, reviewer: String, description: String, quantity: Int, status: StrictCensusDigestStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.description = description
            self.quantity = quantity
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

        func canMoveTo(_ next: StrictCensusDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictCensusDigestStatus.expired
            case .granted:
                return next == StrictCensusDigestStatus.revoked || next == StrictCensusDigestStatus.expired
            case .revoked:
                return next == StrictCensusDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCensusDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict census digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict census digest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> StrictCensusDigest {
            return StrictCensusDigest(
                code: code,
                title: title,
                ownerID: ownerID,
                reviewer: reviewer,
                description: description,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict census digest in status requested.
    static func newStrictCensusDigest(_ code: String, title: String) -> StrictCensusDigest {
        return StrictCensusDigest(
            code: code,
            title: title,
            ownerID: "",
            reviewer: "",
            description: "",
            quantity: 0,
            status: StrictCensusDigestStatus.requested
        )
    }
}
