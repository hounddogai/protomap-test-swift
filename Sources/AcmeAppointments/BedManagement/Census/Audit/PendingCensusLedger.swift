import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending census ledger is in its life cycle.
    enum PendingCensusLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending census ledger as the census team keeps it.
    final class PendingCensusLedger {
        var code: String
        var label: String
        var margin: Double
        var budget: Double
        var clinicianID: String
        var maximum: Double
        var ownerID: String
        var weight: Double
        var status: PendingCensusLedgerStatus

        init(code: String, label: String, margin: Double, budget: Double, clinicianID: String, maximum: Double, ownerID: String, weight: Double, status: PendingCensusLedgerStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.budget = budget
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.ownerID = ownerID
            self.weight = weight
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

        func canMoveTo(_ next: PendingCensusLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingCensusLedgerStatus.draining
            case .draining:
                return next == PendingCensusLedgerStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCensusLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending census ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((margin - weight) * 100).rounded() / 100
        }

        func copyValue() -> PendingCensusLedger {
            return PendingCensusLedger(
                code: code,
                label: label,
                margin: margin,
                budget: budget,
                clinicianID: clinicianID,
                maximum: maximum,
                ownerID: ownerID,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending census ledger in status idle.
    static func newPendingCensusLedger(_ code: String, label: String) -> PendingCensusLedger {
        return PendingCensusLedger(
            code: code,
            label: label,
            margin: 0.0,
            budget: 0.0,
            clinicianID: "",
            maximum: 0.0,
            ownerID: "",
            weight: 0.0,
            status: PendingCensusLedgerStatus.idle
        )
    }
}
