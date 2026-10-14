import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness ledger is in its life cycle.
    enum WitnessLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a witness ledger and its current status.
    final class WitnessLedger {
        var code: String
        var title: String
        var channel: String
        var copay: Double
        var encounterID: String
        var status: WitnessLedgerStatus

        init(code: String, title: String, channel: String, copay: Double, encounterID: String, status: WitnessLedgerStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.copay = copay
            self.encounterID = encounterID
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

        func canMoveTo(_ next: WitnessLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WitnessLedgerStatus.published || next == WitnessLedgerStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WitnessLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> WitnessLedger {
            return WitnessLedger(
                code: code,
                title: title,
                channel: channel,
                copay: copay,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a witness ledger in status created.
    static func newWitnessLedger(_ code: String, title: String) -> WitnessLedger {
        return WitnessLedger(
            code: code,
            title: title,
            channel: "",
            copay: 0.0,
            encounterID: "",
            status: WitnessLedgerStatus.created
        )
    }
}
