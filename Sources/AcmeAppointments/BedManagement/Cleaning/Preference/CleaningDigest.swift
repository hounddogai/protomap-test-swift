import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning digest is in its life cycle.
    enum CleaningDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A cleaning digest as the cleaning team keeps it.
    final class CleaningDigest {
        var code: String
        var title: String
        var refills: Int
        var timezone: String
        var tags: [String]
        var version: Int
        var expiresAt: Int
        var status: CleaningDigestStatus

        init(code: String, title: String, refills: Int, timezone: String, tags: [String], version: Int, expiresAt: Int, status: CleaningDigestStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.timezone = timezone
            self.tags = tags
            self.version = version
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CleaningDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CleaningDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((Double(version) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningDigest {
            return CleaningDigest(
                code: code,
                title: title,
                refills: refills,
                timezone: timezone,
                tags: tags,
                version: version,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a cleaning digest in status created.
    static func newCleaningDigest(_ code: String, title: String) -> CleaningDigest {
        return CleaningDigest(
            code: code,
            title: title,
            refills: 0,
            timezone: "",
            tags: [],
            version: 0,
            expiresAt: 0,
            status: CleaningDigestStatus.created
        )
    }
}
