import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary acuity plan quota is in its life cycle.
    enum PrimaryAcuityPlanQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary acuity plan quota as the acuity plan team keeps it.
    final class PrimaryAcuityPlanQuota {
        var code: String
        var label: String
        var capacity: Int
        var budget: Double
        var description: String
        var externalRef: String
        var specialty: String
        var minimum: Double
        var clinicianID: String
        var reviewer: String
        var status: PrimaryAcuityPlanQuotaStatus

        init(code: String, label: String, capacity: Int, budget: Double, description: String, externalRef: String, specialty: String, minimum: Double, clinicianID: String, reviewer: String, status: PrimaryAcuityPlanQuotaStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.budget = budget
            self.description = description
            self.externalRef = externalRef
            self.specialty = specialty
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PrimaryAcuityPlanQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimaryAcuityPlanQuotaStatus.withdrawn
            case .rejected:
                return next == PrimaryAcuityPlanQuotaStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAcuityPlanQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary acuity plan quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((budget - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAcuityPlanQuota {
            return PrimaryAcuityPlanQuota(
                code: code,
                label: label,
                capacity: capacity,
                budget: budget,
                description: description,
                externalRef: externalRef,
                specialty: specialty,
                minimum: minimum,
                clinicianID: clinicianID,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary acuity plan quota in status proposed.
    static func newPrimaryAcuityPlanQuota(_ code: String, label: String) -> PrimaryAcuityPlanQuota {
        return PrimaryAcuityPlanQuota(
            code: code,
            label: label,
            capacity: 0,
            budget: 0.0,
            description: "",
            externalRef: "",
            specialty: "",
            minimum: 0.0,
            clinicianID: "",
            reviewer: "",
            status: PrimaryAcuityPlanQuotaStatus.proposed
        )
    }
}
