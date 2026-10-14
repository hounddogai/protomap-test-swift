import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census ledger is in its life cycle.
    enum CensusLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a census ledger and its current status.
    final class CensusLedger {
        var code: String
        var name: String
        var diagnosisCode: String
        var cost: Double
        var quantity: Int
        var priority: Int
        var maximum: Double
        var channel: String
        var ownerID: String
        var attributes: [String: String]
        var status: CensusLedgerStatus

        init(code: String, name: String, diagnosisCode: String, cost: Double, quantity: Int, priority: Int, maximum: Double, channel: String, ownerID: String, attributes: [String: String], status: CensusLedgerStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.quantity = quantity
            self.priority = priority
            self.maximum = maximum
            self.channel = channel
            self.ownerID = ownerID
            self.attributes = attributes
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

        func canMoveTo(_ next: CensusLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CensusLedgerStatus.approved || next == CensusLedgerStatus.withdrawn
            case .approved:
                return next == CensusLedgerStatus.rejected
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

        func moveTo(_ next: CensusLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return ((Double(quantity) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> CensusLedger {
            return CensusLedger(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                cost: cost,
                quantity: quantity,
                priority: priority,
                maximum: maximum,
                channel: channel,
                ownerID: ownerID,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a census ledger in status proposed.
    static func newCensusLedger(_ code: String, name: String) -> CensusLedger {
        return CensusLedger(
            code: code,
            name: name,
            diagnosisCode: "",
            cost: 0.0,
            quantity: 0,
            priority: 0,
            maximum: 0.0,
            channel: "",
            ownerID: "",
            attributes: [:],
            status: CensusLedgerStatus.proposed
        )
    }
}
