import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled accession notice is in its life cycle.
    enum ScheduledAccessionNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled accession notice as the accession team keeps it.
    final class ScheduledAccessionNotice {
        var code: String
        var label: String
        var procedureCode: String
        var expiresAt: Int
        var notes: String
        var patientRef: String
        var minimum: Double
        var refills: Int
        var contactEmail: String
        var batchSize: Int
        var status: ScheduledAccessionNoticeStatus

        init(code: String, label: String, procedureCode: String, expiresAt: Int, notes: String, patientRef: String, minimum: Double, refills: Int, contactEmail: String, batchSize: Int, status: ScheduledAccessionNoticeStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.expiresAt = expiresAt
            self.notes = notes
            self.patientRef = patientRef
            self.minimum = minimum
            self.refills = refills
            self.contactEmail = contactEmail
            self.batchSize = batchSize
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

        func canMoveTo(_ next: ScheduledAccessionNoticeStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ScheduledAccessionNoticeStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ScheduledAccessionNoticeStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAccessionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled accession notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((minimum + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAccessionNotice {
            return ScheduledAccessionNotice(
                code: code,
                label: label,
                procedureCode: procedureCode,
                expiresAt: expiresAt,
                notes: notes,
                patientRef: patientRef,
                minimum: minimum,
                refills: refills,
                contactEmail: contactEmail,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled accession notice in status planned.
    static func newScheduledAccessionNotice(_ code: String, label: String) -> ScheduledAccessionNotice {
        return ScheduledAccessionNotice(
            code: code,
            label: label,
            procedureCode: "",
            expiresAt: 0,
            notes: "",
            patientRef: "",
            minimum: 0.0,
            refills: 0,
            contactEmail: "",
            batchSize: 0,
            status: ScheduledAccessionNoticeStatus.planned
        )
    }
}
