import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set milestone is in its life cycle.
    enum OrderSetMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One order set milestone, with what the planners need to act on it.
    final class OrderSetMilestone {
        var code: String
        var label: String
        var limit: Int
        var allergy: String
        var updatedAt: Int
        var clinicianID: String
        var contactEmail: String
        var specialty: String
        var minimum: Double
        var status: OrderSetMilestoneStatus

        init(code: String, label: String, limit: Int, allergy: String, updatedAt: Int, clinicianID: String, contactEmail: String, specialty: String, minimum: Double, status: OrderSetMilestoneStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.clinicianID = clinicianID
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.minimum = minimum
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

        func canMoveTo(_ next: OrderSetMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == OrderSetMilestoneStatus.pending || next == OrderSetMilestoneStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OrderSetMilestoneStatus.suspended
            case .suspended:
                return next == OrderSetMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return ((Double(limit) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetMilestone {
            return OrderSetMilestone(
                code: code,
                label: label,
                limit: limit,
                allergy: allergy,
                updatedAt: updatedAt,
                clinicianID: clinicianID,
                contactEmail: contactEmail,
                specialty: specialty,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set milestone in status draft.
    static func newOrderSetMilestone(_ code: String, label: String) -> OrderSetMilestone {
        return OrderSetMilestone(
            code: code,
            label: label,
            limit: 0,
            allergy: "",
            updatedAt: 0,
            clinicianID: "",
            contactEmail: "",
            specialty: "",
            minimum: 0.0,
            status: OrderSetMilestoneStatus.draft
        )
    }
}
