import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation target is in its life cycle.
    enum RevocationTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A revocation target. Its code is unique within a tenant.
    final class RevocationTarget {
        var code: String
        var title: String
        var ownerID: String
        var pinned: Bool
        var attributes: [String: String]
        var revision: Int
        var name: String
        var durationMinutes: Int
        var status: RevocationTargetStatus

        init(code: String, title: String, ownerID: String, pinned: Bool, attributes: [String: String], revision: Int, name: String, durationMinutes: Int, status: RevocationTargetStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.pinned = pinned
            self.attributes = attributes
            self.revision = revision
            self.name = name
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: RevocationTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == RevocationTargetStatus.revoked
            case .granted:
                return next == RevocationTargetStatus.revoked || next == RevocationTargetStatus.expired
            case .revoked:
                return next == RevocationTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationTarget {
            return RevocationTarget(
                code: code,
                title: title,
                ownerID: ownerID,
                pinned: pinned,
                attributes: attributes,
                revision: revision,
                name: name,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation target in status requested.
    static func newRevocationTarget(_ code: String, title: String) -> RevocationTarget {
        return RevocationTarget(
            code: code,
            title: title,
            ownerID: "",
            pinned: false,
            attributes: [:],
            revision: 0,
            name: "",
            durationMinutes: 0,
            status: RevocationTargetStatus.requested
        )
    }
}
