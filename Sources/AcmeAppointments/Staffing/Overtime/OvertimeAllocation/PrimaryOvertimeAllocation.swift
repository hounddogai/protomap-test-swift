import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary overtime allocation is in its life cycle.
    enum PrimaryOvertimeAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary overtime allocation as the overtime team keeps it.
    final class PrimaryOvertimeAllocation {
        var code: String
        var title: String
        var contactEmail: String
        var retries: Int
        var notes: String
        var allergy: String
        var reviewer: String
        var approved: Bool
        var startsAt: Int
        var status: PrimaryOvertimeAllocationStatus

        init(code: String, title: String, contactEmail: String, retries: Int, notes: String, allergy: String, reviewer: String, approved: Bool, startsAt: Int, status: PrimaryOvertimeAllocationStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.retries = retries
            self.notes = notes
            self.allergy = allergy
            self.reviewer = reviewer
            self.approved = approved
            self.startsAt = startsAt
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

        func canMoveTo(_ next: PrimaryOvertimeAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryOvertimeAllocationStatus.approved || next == PrimaryOvertimeAllocationStatus.rejected
            case .approved:
                return next == PrimaryOvertimeAllocationStatus.withdrawn
            case .rejected:
                return next == PrimaryOvertimeAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOvertimeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary overtime allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary overtime allocation") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(retries) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOvertimeAllocation {
            return PrimaryOvertimeAllocation(
                code: code,
                title: title,
                contactEmail: contactEmail,
                retries: retries,
                notes: notes,
                allergy: allergy,
                reviewer: reviewer,
                approved: approved,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary overtime allocation in status proposed.
    static func newPrimaryOvertimeAllocation(_ code: String, title: String) -> PrimaryOvertimeAllocation {
        return PrimaryOvertimeAllocation(
            code: code,
            title: title,
            contactEmail: "",
            retries: 0,
            notes: "",
            allergy: "",
            reviewer: "",
            approved: false,
            startsAt: 0,
            status: PrimaryOvertimeAllocationStatus.proposed
        )
    }
}
