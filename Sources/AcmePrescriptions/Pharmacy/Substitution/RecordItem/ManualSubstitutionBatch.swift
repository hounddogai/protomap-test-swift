import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual substitution batch is in its life cycle.
    enum ManualSubstitutionBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual substitution batch. Its code is unique within a tenant.
    final class ManualSubstitutionBatch {
        var code: String
        var label: String
        var procedureCode: String
        var revision: Int
        var approved: Bool
        var phone: String
        var discount: Double
        var encounterID: String
        var endsAt: Int
        var title: String
        var status: ManualSubstitutionBatchStatus

        init(code: String, label: String, procedureCode: String, revision: Int, approved: Bool, phone: String, discount: Double, encounterID: String, endsAt: Int, title: String, status: ManualSubstitutionBatchStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.revision = revision
            self.approved = approved
            self.phone = phone
            self.discount = discount
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualSubstitutionBatchStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualSubstitutionBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual substitution batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ManualSubstitutionBatch {
            return ManualSubstitutionBatch(
                code: code,
                label: label,
                procedureCode: procedureCode,
                revision: revision,
                approved: approved,
                phone: phone,
                discount: discount,
                encounterID: encounterID,
                endsAt: endsAt,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual substitution batch in status planned.
    static func newManualSubstitutionBatch(_ code: String, label: String) -> ManualSubstitutionBatch {
        return ManualSubstitutionBatch(
            code: code,
            label: label,
            procedureCode: "",
            revision: 0,
            approved: false,
            phone: "",
            discount: 0.0,
            encounterID: "",
            endsAt: 0,
            title: "",
            status: ManualSubstitutionBatchStatus.planned
        )
    }
}
