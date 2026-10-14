import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning batch is in its life cycle.
    enum CleaningBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a cleaning batch and its current status.
    final class CleaningBatch {
        var code: String
        var label: String
        var locale: String
        var quantity: Int
        var unit: String
        var status: CleaningBatchStatus

        init(code: String, label: String, locale: String, quantity: Int, unit: String, status: CleaningBatchStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.quantity = quantity
            self.unit = unit
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

        func canMoveTo(_ next: CleaningBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CleaningBatchStatus.withdrawn
            case .approved:
                return next == CleaningBatchStatus.withdrawn
            case .rejected:
                return next == CleaningBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CleaningBatch {
            return CleaningBatch(
                code: code,
                label: label,
                locale: locale,
                quantity: quantity,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a cleaning batch in status proposed.
    static func newCleaningBatch(_ code: String, label: String) -> CleaningBatch {
        return CleaningBatch(
            code: code,
            label: label,
            locale: "",
            quantity: 0,
            unit: "",
            status: CleaningBatchStatus.proposed
        )
    }
}
