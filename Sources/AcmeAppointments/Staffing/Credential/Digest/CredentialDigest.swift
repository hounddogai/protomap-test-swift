import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential digest is in its life cycle.
    enum CredentialDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A credential digest. Its code is unique within a tenant.
    final class CredentialDigest {
        var code: String
        var title: String
        var acuity: Int
        var margin: Double
        var phone: String
        var pinned: Bool
        var batchSize: Int
        var copay: Double
        var status: CredentialDigestStatus

        init(code: String, title: String, acuity: Int, margin: Double, phone: String, pinned: Bool, batchSize: Int, copay: Double, status: CredentialDigestStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.margin = margin
            self.phone = phone
            self.pinned = pinned
            self.batchSize = batchSize
            self.copay = copay
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

        func canMoveTo(_ next: CredentialDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CredentialDigestStatus.done || next == CredentialDigestStatus.failed
            case .done:
                return next == CredentialDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((Double(batchSize) + margin) * 100).rounded() / 100
        }

        func copyValue() -> CredentialDigest {
            return CredentialDigest(
                code: code,
                title: title,
                acuity: acuity,
                margin: margin,
                phone: phone,
                pinned: pinned,
                batchSize: batchSize,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential digest in status new.
    static func newCredentialDigest(_ code: String, title: String) -> CredentialDigest {
        return CredentialDigest(
            code: code,
            title: title,
            acuity: 0,
            margin: 0.0,
            phone: "",
            pinned: false,
            batchSize: 0,
            copay: 0.0,
            status: CredentialDigestStatus.new
        )
    }
}
