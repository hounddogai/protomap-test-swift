import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending charge override is in its life cycle.
    enum PendingChargeOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending charge override. Its code is unique within a tenant.
    final class PendingChargeOverride {
        var code: String
        var name: String
        var label: String
        var patientRef: String
        var specialty: String
        var contactEmail: String
        var diagnosisCode: String
        var graceDays: Int
        var summary: String
        var ownerID: String
        var region: String
        var status: PendingChargeOverrideStatus

        init(code: String, name: String, label: String, patientRef: String, specialty: String, contactEmail: String, diagnosisCode: String, graceDays: Int, summary: String, ownerID: String, region: String, status: PendingChargeOverrideStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.patientRef = patientRef
            self.specialty = specialty
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.summary = summary
            self.ownerID = ownerID
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingChargeOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingChargeOverrideStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingChargeOverrideStatus.reopened
            case .reopened:
                return next == PendingChargeOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingChargeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending charge override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending charge override") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> PendingChargeOverride {
            return PendingChargeOverride(
                code: code,
                name: name,
                label: label,
                patientRef: patientRef,
                specialty: specialty,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                graceDays: graceDays,
                summary: summary,
                ownerID: ownerID,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending charge override in status open.
    static func newPendingChargeOverride(_ code: String, name: String) -> PendingChargeOverride {
        return PendingChargeOverride(
            code: code,
            name: name,
            label: "",
            patientRef: "",
            specialty: "",
            contactEmail: "",
            diagnosisCode: "",
            graceDays: 0,
            summary: "",
            ownerID: "",
            region: "",
            status: PendingChargeOverrideStatus.`open`
        )
    }
}
