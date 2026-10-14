import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network ledger is in its life cycle.
    enum NetworkLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A network ledger. Its code is unique within a tenant.
    final class NetworkLedger {
        var code: String
        var title: String
        var budget: Double
        var durationMinutes: Int
        var channel: String
        var encounterID: String
        var minimum: Double
        var status: NetworkLedgerStatus

        init(code: String, title: String, budget: Double, durationMinutes: Int, channel: String, encounterID: String, minimum: Double, status: NetworkLedgerStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.channel = channel
            self.encounterID = encounterID
            self.minimum = minimum
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

        func canMoveTo(_ next: NetworkLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == NetworkLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(durationMinutes) - budget) * 100).rounded() / 100
        }

        func copyValue() -> NetworkLedger {
            return NetworkLedger(
                code: code,
                title: title,
                budget: budget,
                durationMinutes: durationMinutes,
                channel: channel,
                encounterID: encounterID,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a network ledger in status created.
    static func newNetworkLedger(_ code: String, title: String) -> NetworkLedger {
        return NetworkLedger(
            code: code,
            title: title,
            budget: 0.0,
            durationMinutes: 0,
            channel: "",
            encounterID: "",
            minimum: 0.0,
            status: NetworkLedgerStatus.created
        )
    }
}
