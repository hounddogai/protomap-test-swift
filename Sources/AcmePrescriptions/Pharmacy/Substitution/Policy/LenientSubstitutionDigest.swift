import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient substitution digest is in its life cycle.
    enum LenientSubstitutionDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient substitution digest. Its code is unique within a tenant.
    final class LenientSubstitutionDigest {
        var code: String
        var title: String
        var category: String
        var pinned: Bool
        var startsAt: Int
        var archived: Bool
        var status: LenientSubstitutionDigestStatus

        init(code: String, title: String, category: String, pinned: Bool, startsAt: Int, archived: Bool, status: LenientSubstitutionDigestStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.pinned = pinned
            self.startsAt = startsAt
            self.archived = archived
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

        func canMoveTo(_ next: LenientSubstitutionDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientSubstitutionDigestStatus.revoked || next == LenientSubstitutionDigestStatus.expired
            case .granted:
                return next == LenientSubstitutionDigestStatus.expired
            case .revoked:
                return next == LenientSubstitutionDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSubstitutionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient substitution digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> LenientSubstitutionDigest {
            return LenientSubstitutionDigest(
                code: code,
                title: title,
                category: category,
                pinned: pinned,
                startsAt: startsAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a lenient substitution digest in status requested.
    static func newLenientSubstitutionDigest(_ code: String, title: String) -> LenientSubstitutionDigest {
        return LenientSubstitutionDigest(
            code: code,
            title: title,
            category: "",
            pinned: false,
            startsAt: 0,
            archived: false,
            status: LenientSubstitutionDigestStatus.requested
        )
    }
}
