import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential ledger is in its life cycle.
    enum CredentialLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A credential ledger as the credential team keeps it.
    final class CredentialLedger {
        var code: String
        var title: String
        var active: Bool
        var cost: Double
        var checksum: String
        var status: CredentialLedgerStatus

        init(code: String, title: String, active: Bool, cost: Double, checksum: String, status: CredentialLedgerStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.cost = cost
            self.checksum = checksum
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

        func canMoveTo(_ next: CredentialLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == CredentialLedgerStatus.running || next == CredentialLedgerStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CredentialLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential ledger") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> CredentialLedger {
            return CredentialLedger(
                code: code,
                title: title,
                active: active,
                cost: cost,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential ledger in status new.
    static func newCredentialLedger(_ code: String, title: String) -> CredentialLedger {
        return CredentialLedger(
            code: code,
            title: title,
            active: false,
            cost: 0.0,
            checksum: "",
            status: CredentialLedgerStatus.new
        )
    }
}
