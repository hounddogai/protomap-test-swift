import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback result ledger is in its life cycle.
    enum FallbackResultLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One fallback result ledger, with what the planners need to act on it.
    final class FallbackResultLedger {
        var code: String
        var name: String
        var cost: Double
        var externalRef: String
        var specialty: String
        var reviewer: String
        var status: FallbackResultLedgerStatus

        init(code: String, name: String, cost: Double, externalRef: String, specialty: String, reviewer: String, status: FallbackResultLedgerStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.externalRef = externalRef
            self.specialty = specialty
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackResultLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackResultLedgerStatus.validated || next == FallbackResultLedgerStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FallbackResultLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackResultLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback result ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> FallbackResultLedger {
            return FallbackResultLedger(
                code: code,
                name: name,
                cost: cost,
                externalRef: externalRef,
                specialty: specialty,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback result ledger in status created.
    static func newFallbackResultLedger(_ code: String, name: String) -> FallbackResultLedger {
        return FallbackResultLedger(
            code: code,
            name: name,
            cost: 0.0,
            externalRef: "",
            specialty: "",
            reviewer: "",
            status: FallbackResultLedgerStatus.created
        )
    }
}
