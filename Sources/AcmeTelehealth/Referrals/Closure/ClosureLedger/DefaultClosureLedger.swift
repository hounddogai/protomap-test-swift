import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default closure ledger is in its life cycle.
    enum DefaultClosureLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default closure ledger as the closure team keeps it.
    final class DefaultClosureLedger {
        var code: String
        var title: String
        var payer: String
        var reviewer: String
        var batchSize: Int
        var status: DefaultClosureLedgerStatus

        init(code: String, title: String, payer: String, reviewer: String, batchSize: Int, status: DefaultClosureLedgerStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.reviewer = reviewer
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DefaultClosureLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == DefaultClosureLedgerStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultClosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default closure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> DefaultClosureLedger {
            return DefaultClosureLedger(
                code: code,
                title: title,
                payer: payer,
                reviewer: reviewer,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default closure ledger in status new.
    static func newDefaultClosureLedger(_ code: String, title: String) -> DefaultClosureLedger {
        return DefaultClosureLedger(
            code: code,
            title: title,
            payer: "",
            reviewer: "",
            batchSize: 0,
            status: DefaultClosureLedgerStatus.new
        )
    }
}
