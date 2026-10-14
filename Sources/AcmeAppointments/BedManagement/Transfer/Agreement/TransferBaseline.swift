import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer baseline is in its life cycle.
    enum TransferBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A transfer baseline. Its code is unique within a tenant.
    final class TransferBaseline {
        var code: String
        var label: String
        var visible: Bool
        var minimum: Double
        var patientRef: String
        var ward: String
        var channel: String
        var archived: Bool
        var maximum: Double
        var copay: Double
        var dosageMg: Double
        var status: TransferBaselineStatus

        init(code: String, label: String, visible: Bool, minimum: Double, patientRef: String, ward: String, channel: String, archived: Bool, maximum: Double, copay: Double, dosageMg: Double, status: TransferBaselineStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.minimum = minimum
            self.patientRef = patientRef
            self.ward = ward
            self.channel = channel
            self.archived = archived
            self.maximum = maximum
            self.copay = copay
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TransferBaselineStatus.suspended
            case .active:
                return next == TransferBaselineStatus.suspended
            case .suspended:
                return next == TransferBaselineStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("transfer baseline") \(code)"
        }

        func weightedTotal() -> Double {
            return ((minimum - maximum) * 100).rounded() / 100
        }

        func copyValue() -> TransferBaseline {
            return TransferBaseline(
                code: code,
                label: label,
                visible: visible,
                minimum: minimum,
                patientRef: patientRef,
                ward: ward,
                channel: channel,
                archived: archived,
                maximum: maximum,
                copay: copay,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a transfer baseline in status draft.
    static func newTransferBaseline(_ code: String, label: String) -> TransferBaseline {
        return TransferBaseline(
            code: code,
            label: label,
            visible: false,
            minimum: 0.0,
            patientRef: "",
            ward: "",
            channel: "",
            archived: false,
            maximum: 0.0,
            copay: 0.0,
            dosageMg: 0.0,
            status: TransferBaselineStatus.draft
        )
    }
}
