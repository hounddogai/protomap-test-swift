import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential rollup is in its life cycle.
    enum CredentialRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A credential rollup as the credential team keeps it.
    final class CredentialRollup {
        var code: String
        var label: String
        var createdAt: Int
        var refills: Int
        var externalRef: String
        var locale: String
        var status: CredentialRollupStatus

        init(code: String, label: String, createdAt: Int, refills: Int, externalRef: String, locale: String, status: CredentialRollupStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.refills = refills
            self.externalRef = externalRef
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == CredentialRollupStatus.queued || next == CredentialRollupStatus.running
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CredentialRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(refills) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialRollup {
            return CredentialRollup(
                code: code,
                label: label,
                createdAt: createdAt,
                refills: refills,
                externalRef: externalRef,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a credential rollup in status new.
    static func newCredentialRollup(_ code: String, label: String) -> CredentialRollup {
        return CredentialRollup(
            code: code,
            label: label,
            createdAt: 0,
            refills: 0,
            externalRef: "",
            locale: "",
            status: CredentialRollupStatus.new
        )
    }
}
