import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel batch is in its life cycle.
    enum PanelBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel batch and its current status.
    final class PanelBatch {
        var code: String
        var label: String
        var unit: String
        var country: String
        var notes: String
        var segment: String
        var attempts: Int
        var dosageMg: Double
        var bed: String
        var status: PanelBatchStatus

        init(code: String, label: String, unit: String, country: String, notes: String, segment: String, attempts: Int, dosageMg: Double, bed: String, status: PanelBatchStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.country = country
            self.notes = notes
            self.segment = segment
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.bed = bed
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

        func canMoveTo(_ next: PanelBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PanelBatchStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PanelBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((dosageMg + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PanelBatch {
            return PanelBatch(
                code: code,
                label: label,
                unit: unit,
                country: country,
                notes: notes,
                segment: segment,
                attempts: attempts,
                dosageMg: dosageMg,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a panel batch in status proposed.
    static func newPanelBatch(_ code: String, label: String) -> PanelBatch {
        return PanelBatch(
            code: code,
            label: label,
            unit: "",
            country: "",
            notes: "",
            segment: "",
            attempts: 0,
            dosageMg: 0.0,
            bed: "",
            status: PanelBatchStatus.proposed
        )
    }
}
