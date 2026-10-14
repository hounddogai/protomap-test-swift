import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime ledger is in its life cycle.
    enum OvertimeLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A overtime ledger as the overtime team keeps it.
    final class OvertimeLedger {
        var code: String
        var title: String
        var unit: String
        var locale: String
        var minimum: Double
        var status: OvertimeLedgerStatus

        init(code: String, title: String, unit: String, locale: String, minimum: Double, status: OvertimeLedgerStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.locale = locale
            self.minimum = minimum
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

        func canMoveTo(_ next: OvertimeLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == OvertimeLedgerStatus.rejected || next == OvertimeLedgerStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OvertimeLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime ledger") \(code)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> OvertimeLedger {
            return OvertimeLedger(
                code: code,
                title: title,
                unit: unit,
                locale: locale,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a overtime ledger in status proposed.
    static func newOvertimeLedger(_ code: String, title: String) -> OvertimeLedger {
        return OvertimeLedger(
            code: code,
            title: title,
            unit: "",
            locale: "",
            minimum: 0.0,
            status: OvertimeLedgerStatus.proposed
        )
    }
}
