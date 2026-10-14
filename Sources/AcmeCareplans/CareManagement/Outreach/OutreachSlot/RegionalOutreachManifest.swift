import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional outreach manifest is in its life cycle.
    enum RegionalOutreachManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One regional outreach manifest, with what the planners need to act on it.
    final class RegionalOutreachManifest {
        var code: String
        var title: String
        var summary: String
        var patientRef: String
        var ward: String
        var contactEmail: String
        var visitMinutes: Int
        var ownerID: String
        var copay: Double
        var reviewer: String
        var procedureCode: String
        var status: RegionalOutreachManifestStatus

        init(code: String, title: String, summary: String, patientRef: String, ward: String, contactEmail: String, visitMinutes: Int, ownerID: String, copay: Double, reviewer: String, procedureCode: String, status: RegionalOutreachManifestStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.patientRef = patientRef
            self.ward = ward
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
            self.copay = copay
            self.reviewer = reviewer
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RegionalOutreachManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalOutreachManifestStatus.pending || next == RegionalOutreachManifestStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalOutreachManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOutreachManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional outreach manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return ((copay - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOutreachManifest {
            return RegionalOutreachManifest(
                code: code,
                title: title,
                summary: summary,
                patientRef: patientRef,
                ward: ward,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                ownerID: ownerID,
                copay: copay,
                reviewer: reviewer,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional outreach manifest in status draft.
    static func newRegionalOutreachManifest(_ code: String, title: String) -> RegionalOutreachManifest {
        return RegionalOutreachManifest(
            code: code,
            title: title,
            summary: "",
            patientRef: "",
            ward: "",
            contactEmail: "",
            visitMinutes: 0,
            ownerID: "",
            copay: 0.0,
            reviewer: "",
            procedureCode: "",
            status: RegionalOutreachManifestStatus.draft
        )
    }
}
