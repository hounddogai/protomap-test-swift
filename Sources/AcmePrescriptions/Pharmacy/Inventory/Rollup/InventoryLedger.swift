import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory ledger is in its life cycle.
    enum InventoryLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One inventory ledger, with what the planners need to act on it.
    final class InventoryLedger {
        var code: String
        var label: String
        var createdAt: Int
        var acuity: Int
        var maximum: Double
        var description: String
        var pinned: Bool
        var status: InventoryLedgerStatus

        init(code: String, label: String, createdAt: Int, acuity: Int, maximum: Double, description: String, pinned: Bool, status: InventoryLedgerStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.acuity = acuity
            self.maximum = maximum
            self.description = description
            self.pinned = pinned
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

        func canMoveTo(_ next: InventoryLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == InventoryLedgerStatus.running || next == InventoryLedgerStatus.done
            case .queued:
                return next == InventoryLedgerStatus.running
            case .running:
                return next == InventoryLedgerStatus.done
            case .done:
                return next == InventoryLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("inventory ledger") \(code)"
        }

        func weightedLoad() -> Double {
            return ((maximum + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryLedger {
            return InventoryLedger(
                code: code,
                label: label,
                createdAt: createdAt,
                acuity: acuity,
                maximum: maximum,
                description: description,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a inventory ledger in status new.
    static func newInventoryLedger(_ code: String, label: String) -> InventoryLedger {
        return InventoryLedger(
            code: code,
            label: label,
            createdAt: 0,
            acuity: 0,
            maximum: 0.0,
            description: "",
            pinned: false,
            status: InventoryLedgerStatus.new
        )
    }
}
