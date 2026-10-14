import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy entry is in its life cycle.
    enum ProxyEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One proxy entry, with what the planners need to act on it.
    final class ProxyEntry {
        var code: String
        var label: String
        var summary: String
        var timezone: String
        var active: Bool
        var createdAt: Int
        var revision: Int
        var source: String
        var ward: String
        var startsAt: Int
        var status: ProxyEntryStatus

        init(code: String, label: String, summary: String, timezone: String, active: Bool, createdAt: Int, revision: Int, source: String, ward: String, startsAt: Int, status: ProxyEntryStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.timezone = timezone
            self.active = active
            self.createdAt = createdAt
            self.revision = revision
            self.source = source
            self.ward = ward
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ProxyEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ProxyEntryStatus.active || next == ProxyEntryStatus.suspended
            case .active:
                return next == ProxyEntryStatus.suspended || next == ProxyEntryStatus.closed
            case .suspended:
                return next == ProxyEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return (Double(startsAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> ProxyEntry {
            return ProxyEntry(
                code: code,
                label: label,
                summary: summary,
                timezone: timezone,
                active: active,
                createdAt: createdAt,
                revision: revision,
                source: source,
                ward: ward,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a proxy entry in status draft.
    static func newProxyEntry(_ code: String, label: String) -> ProxyEntry {
        return ProxyEntry(
            code: code,
            label: label,
            summary: "",
            timezone: "",
            active: false,
            createdAt: 0,
            revision: 0,
            source: "",
            ward: "",
            startsAt: 0,
            status: ProxyEntryStatus.draft
        )
    }
}
