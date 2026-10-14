import AcmePlatform
import Foundation

extension Labs {
    /// Where a result ledger is in its life cycle.
    enum ResultLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a result ledger and its current status.
    final class ResultLedger {
        var code: String
        var name: String
        var channel: String
        var reviewer: String
        var externalRef: String
        var clinicianID: String
        var amount: Double
        var status: ResultLedgerStatus

        init(code: String, name: String, channel: String, reviewer: String, externalRef: String, clinicianID: String, amount: Double, status: ResultLedgerStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.reviewer = reviewer
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultLedgerStatus) -> Bool {
            switch status {
            case .idle:
                return next == ResultLedgerStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ResultLedgerStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ResultLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ResultLedger {
            return ResultLedger(
                code: code,
                name: name,
                channel: channel,
                reviewer: reviewer,
                externalRef: externalRef,
                clinicianID: clinicianID,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result ledger in status idle.
    static func newResultLedger(_ code: String, name: String) -> ResultLedger {
        return ResultLedger(
            code: code,
            name: name,
            channel: "",
            reviewer: "",
            externalRef: "",
            clinicianID: "",
            amount: 0.0,
            status: ResultLedgerStatus.idle
        )
    }
}
