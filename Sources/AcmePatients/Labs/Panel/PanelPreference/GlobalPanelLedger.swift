import AcmePlatform
import Foundation

extension Labs {
    /// Where a global panel ledger is in its life cycle.
    enum GlobalPanelLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global panel ledger as the panel team keeps it.
    final class GlobalPanelLedger {
        var code: String
        var name: String
        var region: String
        var minimum: Double
        var contactEmail: String
        var encounterID: String
        var payer: String
        var status: GlobalPanelLedgerStatus

        init(code: String, name: String, region: String, minimum: Double, contactEmail: String, encounterID: String, payer: String, status: GlobalPanelLedgerStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.encounterID = encounterID
            self.payer = payer
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

        func canMoveTo(_ next: GlobalPanelLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalPanelLedgerStatus.draining || next == GlobalPanelLedgerStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalPanelLedgerStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalPanelLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global panel ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> GlobalPanelLedger {
            return GlobalPanelLedger(
                code: code,
                name: name,
                region: region,
                minimum: minimum,
                contactEmail: contactEmail,
                encounterID: encounterID,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global panel ledger in status idle.
    static func newGlobalPanelLedger(_ code: String, name: String) -> GlobalPanelLedger {
        return GlobalPanelLedger(
            code: code,
            name: name,
            region: "",
            minimum: 0.0,
            contactEmail: "",
            encounterID: "",
            payer: "",
            status: GlobalPanelLedgerStatus.idle
        )
    }
}
