import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach segment is in its life cycle.
    enum OutreachSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A outreach segment. Its code is unique within a tenant.
    final class OutreachSegment {
        var code: String
        var title: String
        var attempts: Int
        var priority: Int
        var contactEmail: String
        var bed: String
        var cost: Double
        var status: OutreachSegmentStatus

        init(code: String, title: String, attempts: Int, priority: Int, contactEmail: String, bed: String, cost: Double, status: OutreachSegmentStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.priority = priority
            self.contactEmail = contactEmail
            self.bed = bed
            self.cost = cost
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

        func canMoveTo(_ next: OutreachSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OutreachSegmentStatus.approved || next == OutreachSegmentStatus.withdrawn
            case .approved:
                return next == OutreachSegmentStatus.rejected || next == OutreachSegmentStatus.withdrawn
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

        func moveTo(_ next: OutreachSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return ((Double(attempts) - cost) * 100).rounded() / 100
        }

        func copyValue() -> OutreachSegment {
            return OutreachSegment(
                code: code,
                title: title,
                attempts: attempts,
                priority: priority,
                contactEmail: contactEmail,
                bed: bed,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach segment in status proposed.
    static func newOutreachSegment(_ code: String, title: String) -> OutreachSegment {
        return OutreachSegment(
            code: code,
            title: title,
            attempts: 0,
            priority: 0,
            contactEmail: "",
            bed: "",
            cost: 0.0,
            status: OutreachSegmentStatus.proposed
        )
    }
}
