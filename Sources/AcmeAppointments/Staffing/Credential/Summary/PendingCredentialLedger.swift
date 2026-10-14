import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending credential ledger is in its life cycle.
    enum PendingCredentialLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending credential ledger as the credential team keeps it.
    final class PendingCredentialLedger {
        var code: String
        var name: String
        var visitMinutes: Int
        var copay: Double
        var locale: String
        var phone: String
        var summary: String
        var status: PendingCredentialLedgerStatus

        init(code: String, name: String, visitMinutes: Int, copay: Double, locale: String, phone: String, summary: String, status: PendingCredentialLedgerStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.locale = locale
            self.phone = phone
            self.summary = summary
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

        func canMoveTo(_ next: PendingCredentialLedgerStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PendingCredentialLedgerStatus.revoked
            case .revoked:
                return next == PendingCredentialLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCredentialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending credential ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((copay - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCredentialLedger {
            return PendingCredentialLedger(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                copay: copay,
                locale: locale,
                phone: phone,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending credential ledger in status requested.
    static func newPendingCredentialLedger(_ code: String, name: String) -> PendingCredentialLedger {
        return PendingCredentialLedger(
            code: code,
            name: name,
            visitMinutes: 0,
            copay: 0.0,
            locale: "",
            phone: "",
            summary: "",
            status: PendingCredentialLedgerStatus.requested
        )
    }
}
