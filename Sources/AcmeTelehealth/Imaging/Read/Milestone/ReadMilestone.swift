import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read milestone is in its life cycle.
    enum ReadMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A read milestone. Its code is unique within a tenant.
    final class ReadMilestone {
        var code: String
        var name: String
        var attempts: Int
        var pinned: Bool
        var specialty: String
        var notes: String
        var segment: String
        var dosageMg: Double
        var clinicianID: String
        var cost: Double
        var status: ReadMilestoneStatus

        init(code: String, name: String, attempts: Int, pinned: Bool, specialty: String, notes: String, segment: String, dosageMg: Double, clinicianID: String, cost: Double, status: ReadMilestoneStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.pinned = pinned
            self.specialty = specialty
            self.notes = notes
            self.segment = segment
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.cost = cost
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

        func canMoveTo(_ next: ReadMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                return next == ReadMilestoneStatus.completed
            case .scheduled:
                return next == ReadMilestoneStatus.completed
            case .inProgress:
                return next == ReadMilestoneStatus.completed
            case .completed:
                return next == ReadMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("read milestone") \(code)"
        }

        func effectiveValue() -> Double {
            return ((cost - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ReadMilestone {
            return ReadMilestone(
                code: code,
                name: name,
                attempts: attempts,
                pinned: pinned,
                specialty: specialty,
                notes: notes,
                segment: segment,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a read milestone in status planned.
    static func newReadMilestone(_ code: String, name: String) -> ReadMilestone {
        return ReadMilestone(
            code: code,
            name: name,
            attempts: 0,
            pinned: false,
            specialty: "",
            notes: "",
            segment: "",
            dosageMg: 0.0,
            clinicianID: "",
            cost: 0.0,
            status: ReadMilestoneStatus.planned
        )
    }
}
