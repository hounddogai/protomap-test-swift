import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary acuity plan policy is in its life cycle.
    enum PrimaryAcuityPlanPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary acuity plan policy. Its code is unique within a tenant.
    final class PrimaryAcuityPlanPolicy {
        var code: String
        var label: String
        var budget: Double
        var description: String
        var category: String
        var checksum: String
        var approved: Bool
        var specialty: String
        var sequence: Int
        var status: PrimaryAcuityPlanPolicyStatus

        init(code: String, label: String, budget: Double, description: String, category: String, checksum: String, approved: Bool, specialty: String, sequence: Int, status: PrimaryAcuityPlanPolicyStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.description = description
            self.category = category
            self.checksum = checksum
            self.approved = approved
            self.specialty = specialty
            self.sequence = sequence
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

        func canMoveTo(_ next: PrimaryAcuityPlanPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryAcuityPlanPolicyStatus.rejected || next == PrimaryAcuityPlanPolicyStatus.withdrawn
            case .approved:
                return next == PrimaryAcuityPlanPolicyStatus.rejected || next == PrimaryAcuityPlanPolicyStatus.withdrawn
            case .rejected:
                return next == PrimaryAcuityPlanPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAcuityPlanPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary acuity plan policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary acuity plan policy") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(sequence) - budget) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAcuityPlanPolicy {
            return PrimaryAcuityPlanPolicy(
                code: code,
                label: label,
                budget: budget,
                description: description,
                category: category,
                checksum: checksum,
                approved: approved,
                specialty: specialty,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary acuity plan policy in status proposed.
    static func newPrimaryAcuityPlanPolicy(_ code: String, label: String) -> PrimaryAcuityPlanPolicy {
        return PrimaryAcuityPlanPolicy(
            code: code,
            label: label,
            budget: 0.0,
            description: "",
            category: "",
            checksum: "",
            approved: false,
            specialty: "",
            sequence: 0,
            status: PrimaryAcuityPlanPolicyStatus.proposed
        )
    }
}
