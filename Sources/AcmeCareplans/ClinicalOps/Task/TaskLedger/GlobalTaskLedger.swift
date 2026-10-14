import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global task ledger is in its life cycle.
    enum GlobalTaskLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global task ledger as the task team keeps it.
    final class GlobalTaskLedger {
        var code: String
        var title: String
        var floorValue: Double
        var country: String
        var margin: Double
        var unit: String
        var threshold: Double
        var version: Int
        var label: String
        var capacity: Int
        var status: GlobalTaskLedgerStatus

        init(code: String, title: String, floorValue: Double, country: String, margin: Double, unit: String, threshold: Double, version: Int, label: String, capacity: Int, status: GlobalTaskLedgerStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.country = country
            self.margin = margin
            self.unit = unit
            self.threshold = threshold
            self.version = version
            self.label = label
            self.capacity = capacity
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

        func canMoveTo(_ next: GlobalTaskLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalTaskLedgerStatus.retired
            case .validated:
                return next == GlobalTaskLedgerStatus.published || next == GlobalTaskLedgerStatus.retired
            case .published:
                return next == GlobalTaskLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalTaskLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global task ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((margin - threshold) * 100).rounded() / 100
        }

        func copyValue() -> GlobalTaskLedger {
            return GlobalTaskLedger(
                code: code,
                title: title,
                floorValue: floorValue,
                country: country,
                margin: margin,
                unit: unit,
                threshold: threshold,
                version: version,
                label: label,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global task ledger in status created.
    static func newGlobalTaskLedger(_ code: String, title: String) -> GlobalTaskLedger {
        return GlobalTaskLedger(
            code: code,
            title: title,
            floorValue: 0.0,
            country: "",
            margin: 0.0,
            unit: "",
            threshold: 0.0,
            version: 0,
            label: "",
            capacity: 0,
            status: GlobalTaskLedgerStatus.created
        )
    }
}
