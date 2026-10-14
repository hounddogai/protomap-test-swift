import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual reference range record is in its life cycle.
    enum ManualReferenceRangeRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual reference range record. Its code is unique within a tenant.
    final class ManualReferenceRangeRecord {
        var code: String
        var label: String
        var title: String
        var payer: String
        var pinned: Bool
        var bed: String
        var discount: Double
        var clinicianID: String
        var copay: Double
        var status: ManualReferenceRangeRecordStatus

        init(code: String, label: String, title: String, payer: String, pinned: Bool, bed: String, discount: Double, clinicianID: String, copay: Double, status: ManualReferenceRangeRecordStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.payer = payer
            self.pinned = pinned
            self.bed = bed
            self.discount = discount
            self.clinicianID = clinicianID
            self.copay = copay
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

        func canMoveTo(_ next: ManualReferenceRangeRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualReferenceRangeRecordStatus.approved || next == ManualReferenceRangeRecordStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualReferenceRangeRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualReferenceRangeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual reference range record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netTotal() -> Double {
            return ((discount - copay) * 100).rounded() / 100
        }

        func copyValue() -> ManualReferenceRangeRecord {
            return ManualReferenceRangeRecord(
                code: code,
                label: label,
                title: title,
                payer: payer,
                pinned: pinned,
                bed: bed,
                discount: discount,
                clinicianID: clinicianID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual reference range record in status proposed.
    static func newManualReferenceRangeRecord(_ code: String, label: String) -> ManualReferenceRangeRecord {
        return ManualReferenceRangeRecord(
            code: code,
            label: label,
            title: "",
            payer: "",
            pinned: false,
            bed: "",
            discount: 0.0,
            clinicianID: "",
            copay: 0.0,
            status: ManualReferenceRangeRecordStatus.proposed
        )
    }
}
