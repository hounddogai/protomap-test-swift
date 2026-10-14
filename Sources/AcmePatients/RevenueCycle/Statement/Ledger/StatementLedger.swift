import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement ledger is in its life cycle.
    enum StatementLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a statement ledger and its current status.
    final class StatementLedger {
        var code: String
        var label: String
        var channel: String
        var maximum: Double
        var timezone: String
        var procedureCode: String
        var source: String
        var name: String
        var status: StatementLedgerStatus

        init(code: String, label: String, channel: String, maximum: Double, timezone: String, procedureCode: String, source: String, name: String, status: StatementLedgerStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.maximum = maximum
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.source = source
            self.name = name
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

        func canMoveTo(_ next: StatementLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == StatementLedgerStatus.expired
            case .granted:
                return next == StatementLedgerStatus.revoked || next == StatementLedgerStatus.expired
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

        func moveTo(_ next: StatementLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("statement ledger") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> StatementLedger {
            return StatementLedger(
                code: code,
                label: label,
                channel: channel,
                maximum: maximum,
                timezone: timezone,
                procedureCode: procedureCode,
                source: source,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a statement ledger in status requested.
    static func newStatementLedger(_ code: String, label: String) -> StatementLedger {
        return StatementLedger(
            code: code,
            label: label,
            channel: "",
            maximum: 0.0,
            timezone: "",
            procedureCode: "",
            source: "",
            name: "",
            status: StatementLedgerStatus.requested
        )
    }
}
