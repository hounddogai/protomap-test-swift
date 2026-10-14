import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered care protocol ledger is in its life cycle.
    enum TieredCareProtocolLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a tiered care protocol ledger and its current status.
    final class TieredCareProtocolLedger {
        var code: String
        var name: String
        var cost: Double
        var reviewer: String
        var retries: Int
        var encounterID: String
        var acuity: Int
        var status: TieredCareProtocolLedgerStatus

        init(code: String, name: String, cost: Double, reviewer: String, retries: Int, encounterID: String, acuity: Int, status: TieredCareProtocolLedgerStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.reviewer = reviewer
            self.retries = retries
            self.encounterID = encounterID
            self.acuity = acuity
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

        func canMoveTo(_ next: TieredCareProtocolLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TieredCareProtocolLedgerStatus.stopped
            case .draining:
                return next == TieredCareProtocolLedgerStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(acuity) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareProtocolLedger {
            return TieredCareProtocolLedger(
                code: code,
                name: name,
                cost: cost,
                reviewer: reviewer,
                retries: retries,
                encounterID: encounterID,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered care protocol ledger in status idle.
    static func newTieredCareProtocolLedger(_ code: String, name: String) -> TieredCareProtocolLedger {
        return TieredCareProtocolLedger(
            code: code,
            name: name,
            cost: 0.0,
            reviewer: "",
            retries: 0,
            encounterID: "",
            acuity: 0,
            status: TieredCareProtocolLedgerStatus.idle
        )
    }
}
