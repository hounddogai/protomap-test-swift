import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel record is in its life cycle.
    enum PanelRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A panel record. Its code is unique within a tenant.
    final class PanelRecord {
        var code: String
        var label: String
        var archived: Bool
        var clinicianID: String
        var dosageMg: Double
        var contactEmail: String
        var approved: Bool
        var startsAt: Int
        var endsAt: Int
        var bed: String
        var status: PanelRecordStatus

        init(code: String, label: String, archived: Bool, clinicianID: String, dosageMg: Double, contactEmail: String, approved: Bool, startsAt: Int, endsAt: Int, bed: String, status: PanelRecordStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.contactEmail = contactEmail
            self.approved = approved
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.bed = bed
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

        func canMoveTo(_ next: PanelRecordStatus) -> Bool {
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
                return next == PanelRecordStatus.completed || next == PanelRecordStatus.cancelled
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

        func moveTo(_ next: PanelRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("panel record") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(endsAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> PanelRecord {
            return PanelRecord(
                code: code,
                label: label,
                archived: archived,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                contactEmail: contactEmail,
                approved: approved,
                startsAt: startsAt,
                endsAt: endsAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel record in status planned.
    static func newPanelRecord(_ code: String, label: String) -> PanelRecord {
        return PanelRecord(
            code: code,
            label: label,
            archived: false,
            clinicianID: "",
            dosageMg: 0.0,
            contactEmail: "",
            approved: false,
            startsAt: 0,
            endsAt: 0,
            bed: "",
            status: PanelRecordStatus.planned
        )
    }
}
