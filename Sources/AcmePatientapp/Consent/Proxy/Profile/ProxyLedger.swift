import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy ledger is in its life cycle.
    enum ProxyLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One proxy ledger, with what the planners need to act on it.
    final class ProxyLedger {
        var code: String
        var label: String
        var unit: String
        var tags: [String]
        var minimum: Double
        var status: ProxyLedgerStatus

        init(code: String, label: String, unit: String, tags: [String], minimum: Double, status: ProxyLedgerStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.tags = tags
            self.minimum = minimum
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

        func canMoveTo(_ next: ProxyLedgerStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProxyLedgerStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ProxyLedgerStatus.closed
            case .suspended:
                return next == ProxyLedgerStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("proxy ledger") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> ProxyLedger {
            return ProxyLedger(code: code, label: label, unit: unit, tags: tags, minimum: minimum, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a proxy ledger in status draft.
    static func newProxyLedger(_ code: String, label: String) -> ProxyLedger {
        return ProxyLedger(
            code: code,
            label: label,
            unit: "",
            tags: [],
            minimum: 0.0,
            status: ProxyLedgerStatus.draft
        )
    }
}
