import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual credential mapping is in its life cycle.
    enum ManualCredentialMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual credential mapping and its current status.
    final class ManualCredentialMapping {
        var code: String
        var name: String
        var durationMinutes: Int
        var tags: [String]
        var archived: Bool
        var source: String
        var active: Bool
        var timezone: String
        var threshold: Double
        var status: ManualCredentialMappingStatus

        init(code: String, name: String, durationMinutes: Int, tags: [String], archived: Bool, source: String, active: Bool, timezone: String, threshold: Double, status: ManualCredentialMappingStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.archived = archived
            self.source = source
            self.active = active
            self.timezone = timezone
            self.threshold = threshold
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

        func canMoveTo(_ next: ManualCredentialMappingStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ManualCredentialMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual credential mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual credential mapping") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return (threshold * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ManualCredentialMapping {
            return ManualCredentialMapping(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                tags: tags,
                archived: archived,
                source: source,
                active: active,
                timezone: timezone,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual credential mapping in status requested.
    static func newManualCredentialMapping(_ code: String, name: String) -> ManualCredentialMapping {
        return ManualCredentialMapping(
            code: code,
            name: name,
            durationMinutes: 0,
            tags: [],
            archived: false,
            source: "",
            active: false,
            timezone: "",
            threshold: 0.0,
            status: ManualCredentialMappingStatus.requested
        )
    }
}
