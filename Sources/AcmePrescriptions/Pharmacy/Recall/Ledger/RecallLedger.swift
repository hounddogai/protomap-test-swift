import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall ledger is in its life cycle.
    enum RecallLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A recall ledger as the recall team keeps it.
    final class RecallLedger {
        var code: String
        var name: String
        var bed: String
        var weight: Double
        var attributes: [String: String]
        var margin: Double
        var acuity: Int
        var status: RecallLedgerStatus

        init(code: String, name: String, bed: String, weight: Double, attributes: [String: String], margin: Double, acuity: Int, status: RecallLedgerStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.weight = weight
            self.attributes = attributes
            self.margin = margin
            self.acuity = acuity
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

        func canMoveTo(_ next: RecallLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RecallLedgerStatus.approved
            case .approved:
                return next == RecallLedgerStatus.rejected || next == RecallLedgerStatus.withdrawn
            case .rejected:
                return next == RecallLedgerStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall ledger") \(code)"
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

        func weightedVolume() -> Double {
            return ((weight + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RecallLedger {
            return RecallLedger(
                code: code,
                name: name,
                bed: bed,
                weight: weight,
                attributes: attributes,
                margin: margin,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall ledger in status proposed.
    static func newRecallLedger(_ code: String, name: String) -> RecallLedger {
        return RecallLedger(
            code: code,
            name: name,
            bed: "",
            weight: 0.0,
            attributes: [:],
            margin: 0.0,
            acuity: 0,
            status: RecallLedgerStatus.proposed
        )
    }
}
