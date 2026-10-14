import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped revocation ledger is in its life cycle.
    enum CappedRevocationLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped revocation ledger. Its code is unique within a tenant.
    final class CappedRevocationLedger {
        var code: String
        var name: String
        var patientRef: String
        var channel: String
        var expiresAt: Int
        var status: CappedRevocationLedgerStatus

        init(code: String, name: String, patientRef: String, channel: String, expiresAt: Int, status: CappedRevocationLedgerStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.channel = channel
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedRevocationLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedRevocationLedgerStatus.done
            case .running:
                return next == CappedRevocationLedgerStatus.done || next == CappedRevocationLedgerStatus.failed
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

        func moveTo(_ next: CappedRevocationLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped revocation ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> CappedRevocationLedger {
            return CappedRevocationLedger(
                code: code,
                name: name,
                patientRef: patientRef,
                channel: channel,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped revocation ledger in status new.
    static func newCappedRevocationLedger(_ code: String, name: String) -> CappedRevocationLedger {
        return CappedRevocationLedger(
            code: code,
            name: name,
            patientRef: "",
            channel: "",
            expiresAt: 0,
            status: CappedRevocationLedgerStatus.new
        )
    }
}
