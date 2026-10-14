import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential manifest is in its life cycle.
    enum CredentialManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A credential manifest as the credential team keeps it.
    final class CredentialManifest {
        var code: String
        var name: String
        var tags: [String]
        var revision: Int
        var facility: String
        var region: String
        var status: CredentialManifestStatus

        init(code: String, name: String, tags: [String], revision: Int, facility: String, region: String, status: CredentialManifestStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.revision = revision
            self.facility = facility
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialManifestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CredentialManifestStatus.rejected || next == CredentialManifestStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CredentialManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("credential manifest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> CredentialManifest {
            return CredentialManifest(
                code: code,
                name: name,
                tags: tags,
                revision: revision,
                facility: facility,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential manifest in status proposed.
    static func newCredentialManifest(_ code: String, name: String) -> CredentialManifest {
        return CredentialManifest(
            code: code,
            name: name,
            tags: [],
            revision: 0,
            facility: "",
            region: "",
            status: CredentialManifestStatus.proposed
        )
    }
}
