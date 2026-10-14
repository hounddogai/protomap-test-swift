import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending assessment segment is in its life cycle.
    enum PendingAssessmentSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending assessment segment, with what the planners need to act on it.
    final class PendingAssessmentSegment {
        var code: String
        var name: String
        var procedureCode: String
        var contactEmail: String
        var pinned: Bool
        var capacity: Int
        var amount: Double
        var attempts: Int
        var reviewer: String
        var status: PendingAssessmentSegmentStatus

        init(code: String, name: String, procedureCode: String, contactEmail: String, pinned: Bool, capacity: Int, amount: Double, attempts: Int, reviewer: String, status: PendingAssessmentSegmentStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.capacity = capacity
            self.amount = amount
            self.attempts = attempts
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

        func canMoveTo(_ next: PendingAssessmentSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingAssessmentSegmentStatus.approved || next == PendingAssessmentSegmentStatus.withdrawn
            case .approved:
                return next == PendingAssessmentSegmentStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingAssessmentSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending assessment segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending assessment segment") \(code)"
        }

        func netValue() -> Double {
            return (amount * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> PendingAssessmentSegment {
            return PendingAssessmentSegment(
                code: code,
                name: name,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                pinned: pinned,
                capacity: capacity,
                amount: amount,
                attempts: attempts,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending assessment segment in status proposed.
    static func newPendingAssessmentSegment(_ code: String, name: String) -> PendingAssessmentSegment {
        return PendingAssessmentSegment(
            code: code,
            name: name,
            procedureCode: "",
            contactEmail: "",
            pinned: false,
            capacity: 0,
            amount: 0.0,
            attempts: 0,
            reviewer: "",
            status: PendingAssessmentSegmentStatus.proposed
        )
    }
}
