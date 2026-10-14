import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched risk score ledger is in its life cycle.
    enum BatchedRiskScoreLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched risk score ledger, with what the planners need to act on it.
    final class BatchedRiskScoreLedger {
        var code: String
        var label: String
        var channel: String
        var copay: Double
        var attributes: [String: String]
        var bed: String
        var facility: String
        var status: BatchedRiskScoreLedgerStatus

        init(code: String, label: String, channel: String, copay: Double, attributes: [String: String], bed: String, facility: String, status: BatchedRiskScoreLedgerStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.copay = copay
            self.attributes = attributes
            self.bed = bed
            self.facility = facility
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

        func canMoveTo(_ next: BatchedRiskScoreLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedRiskScoreLedgerStatus.withdrawn
            case .rejected:
                return next == BatchedRiskScoreLedgerStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRiskScoreLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched risk score ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> BatchedRiskScoreLedger {
            return BatchedRiskScoreLedger(
                code: code,
                label: label,
                channel: channel,
                copay: copay,
                attributes: attributes,
                bed: bed,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched risk score ledger in status proposed.
    static func newBatchedRiskScoreLedger(_ code: String, label: String) -> BatchedRiskScoreLedger {
        return BatchedRiskScoreLedger(
            code: code,
            label: label,
            channel: "",
            copay: 0.0,
            attributes: [:],
            bed: "",
            facility: "",
            status: BatchedRiskScoreLedgerStatus.proposed
        )
    }
}
