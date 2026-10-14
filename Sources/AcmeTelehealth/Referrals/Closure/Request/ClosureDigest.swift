import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure digest is in its life cycle.
    enum ClosureDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A closure digest as the closure team keeps it.
    final class ClosureDigest {
        var code: String
        var label: String
        var ratio: Double
        var phone: String
        var retries: Int
        var encounterID: String
        var status: ClosureDigestStatus

        init(code: String, label: String, ratio: Double, phone: String, retries: Int, encounterID: String, status: ClosureDigestStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.phone = phone
            self.retries = retries
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ClosureDigestStatus) -> Bool {
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
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ClosureDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((Double(retries) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ClosureDigest {
            return ClosureDigest(
                code: code,
                label: label,
                ratio: ratio,
                phone: phone,
                retries: retries,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a closure digest in status requested.
    static func newClosureDigest(_ code: String, label: String) -> ClosureDigest {
        return ClosureDigest(
            code: code,
            label: label,
            ratio: 0.0,
            phone: "",
            retries: 0,
            encounterID: "",
            status: ClosureDigestStatus.requested
        )
    }
}
