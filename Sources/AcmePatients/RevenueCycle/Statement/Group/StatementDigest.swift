import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement digest is in its life cycle.
    enum StatementDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A statement digest as the statement team keeps it.
    final class StatementDigest {
        var code: String
        var label: String
        var startsAt: Int
        var phone: String
        var payer: String
        var version: Int
        var status: StatementDigestStatus

        init(code: String, label: String, startsAt: Int, phone: String, payer: String, version: Int, status: StatementDigestStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.phone = phone
            self.payer = payer
            self.version = version
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

        func canMoveTo(_ next: StatementDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == StatementDigestStatus.granted || next == StatementDigestStatus.revoked
            case .granted:
                return next == StatementDigestStatus.revoked
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

        func moveTo(_ next: StatementDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("statement digest") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(version) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StatementDigest {
            return StatementDigest(
                code: code,
                label: label,
                startsAt: startsAt,
                phone: phone,
                payer: payer,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement digest in status requested.
    static func newStatementDigest(_ code: String, label: String) -> StatementDigest {
        return StatementDigest(
            code: code,
            label: label,
            startsAt: 0,
            phone: "",
            payer: "",
            version: 0,
            status: StatementDigestStatus.requested
        )
    }
}
