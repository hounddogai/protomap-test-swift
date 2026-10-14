import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional statement plan is in its life cycle.
    enum RegionalStatementPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a regional statement plan and its current status.
    final class RegionalStatementPlan {
        var code: String
        var title: String
        var label: String
        var expiresAt: Int
        var minimum: Double
        var contactEmail: String
        var acuity: Int
        var notes: String
        var specialty: String
        var status: RegionalStatementPlanStatus

        init(code: String, title: String, label: String, expiresAt: Int, minimum: Double, contactEmail: String, acuity: Int, notes: String, specialty: String, status: RegionalStatementPlanStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.notes = notes
            self.specialty = specialty
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

        func canMoveTo(_ next: RegionalStatementPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalStatementPlanStatus.approved || next == RegionalStatementPlanStatus.withdrawn
            case .approved:
                return next == RegionalStatementPlanStatus.rejected
            case .rejected:
                return next == RegionalStatementPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalStatementPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional statement plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStatementPlan {
            return RegionalStatementPlan(
                code: code,
                title: title,
                label: label,
                expiresAt: expiresAt,
                minimum: minimum,
                contactEmail: contactEmail,
                acuity: acuity,
                notes: notes,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional statement plan in status proposed.
    static func newRegionalStatementPlan(_ code: String, title: String) -> RegionalStatementPlan {
        return RegionalStatementPlan(
            code: code,
            title: title,
            label: "",
            expiresAt: 0,
            minimum: 0.0,
            contactEmail: "",
            acuity: 0,
            notes: "",
            specialty: "",
            status: RegionalStatementPlanStatus.proposed
        )
    }
}
