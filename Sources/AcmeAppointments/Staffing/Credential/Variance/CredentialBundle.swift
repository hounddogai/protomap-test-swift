import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential bundle is in its life cycle.
    enum CredentialBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a credential bundle and its current status.
    final class CredentialBundle {
        var code: String
        var name: String
        var weight: Double
        var checksum: String
        var copay: Double
        var contactEmail: String
        var revision: Int
        var status: CredentialBundleStatus

        init(code: String, name: String, weight: Double, checksum: String, copay: Double, contactEmail: String, revision: Int, status: CredentialBundleStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.checksum = checksum
            self.copay = copay
            self.contactEmail = contactEmail
            self.revision = revision
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

        func canMoveTo(_ next: CredentialBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CredentialBundleStatus.suspended || next == CredentialBundleStatus.closed
            case .suspended:
                return next == CredentialBundleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("credential bundle") \(code)"
        }

        func weightedVolume() -> Double {
            return (Double(revision) * copay * 100).rounded() / 100
        }

        func copyValue() -> CredentialBundle {
            return CredentialBundle(
                code: code,
                name: name,
                weight: weight,
                checksum: checksum,
                copay: copay,
                contactEmail: contactEmail,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a credential bundle in status draft.
    static func newCredentialBundle(_ code: String, name: String) -> CredentialBundle {
        return CredentialBundle(
            code: code,
            name: name,
            weight: 0.0,
            checksum: "",
            copay: 0.0,
            contactEmail: "",
            revision: 0,
            status: CredentialBundleStatus.draft
        )
    }
}
