import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary bed board ledger is in its life cycle.
    enum PrimaryBedBoardLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary bed board ledger. Its code is unique within a tenant.
    final class PrimaryBedBoardLedger {
        var code: String
        var label: String
        var minimum: Double
        var allergy: String
        var priority: Int
        var status: PrimaryBedBoardLedgerStatus

        init(code: String, label: String, minimum: Double, allergy: String, priority: Int, status: PrimaryBedBoardLedgerStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.allergy = allergy
            self.priority = priority
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

        func canMoveTo(_ next: PrimaryBedBoardLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryBedBoardLedgerStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryBedBoardLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryBedBoardLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary bed board ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return (minimum * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryBedBoardLedger {
            return PrimaryBedBoardLedger(
                code: code,
                label: label,
                minimum: minimum,
                allergy: allergy,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary bed board ledger in status created.
    static func newPrimaryBedBoardLedger(_ code: String, label: String) -> PrimaryBedBoardLedger {
        return PrimaryBedBoardLedger(
            code: code,
            label: label,
            minimum: 0.0,
            allergy: "",
            priority: 0,
            status: PrimaryBedBoardLedgerStatus.created
        )
    }
}
