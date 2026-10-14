import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped float pool assignment is in its life cycle.
    enum CappedFloatPoolAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped float pool assignment. Its code is unique within a tenant.
    final class CappedFloatPoolAssignment {
        var code: String
        var label: String
        var segment: String
        var contactEmail: String
        var priority: Int
        var batchSize: Int
        var title: String
        var specialty: String
        var ownerID: String
        var refills: Int
        var sequence: Int
        var status: CappedFloatPoolAssignmentStatus

        init(code: String, label: String, segment: String, contactEmail: String, priority: Int, batchSize: Int, title: String, specialty: String, ownerID: String, refills: Int, sequence: Int, status: CappedFloatPoolAssignmentStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.contactEmail = contactEmail
            self.priority = priority
            self.batchSize = batchSize
            self.title = title
            self.specialty = specialty
            self.ownerID = ownerID
            self.refills = refills
            self.sequence = sequence
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

        func canMoveTo(_ next: CappedFloatPoolAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedFloatPoolAssignmentStatus.inProgress || next == CappedFloatPoolAssignmentStatus.completed
            case .inProgress:
                return next == CappedFloatPoolAssignmentStatus.completed || next == CappedFloatPoolAssignmentStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CappedFloatPoolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped float pool assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((Double(sequence) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CappedFloatPoolAssignment {
            return CappedFloatPoolAssignment(
                code: code,
                label: label,
                segment: segment,
                contactEmail: contactEmail,
                priority: priority,
                batchSize: batchSize,
                title: title,
                specialty: specialty,
                ownerID: ownerID,
                refills: refills,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped float pool assignment in status planned.
    static func newCappedFloatPoolAssignment(_ code: String, label: String) -> CappedFloatPoolAssignment {
        return CappedFloatPoolAssignment(
            code: code,
            label: label,
            segment: "",
            contactEmail: "",
            priority: 0,
            batchSize: 0,
            title: "",
            specialty: "",
            ownerID: "",
            refills: 0,
            sequence: 0,
            status: CappedFloatPoolAssignmentStatus.planned
        )
    }
}
