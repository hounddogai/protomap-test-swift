import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient skill mix assignment is in its life cycle.
    enum LenientSkillMixAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient skill mix assignment. Its code is unique within a tenant.
    final class LenientSkillMixAssignment {
        var code: String
        var title: String
        var capacity: Int
        var unit: String
        var patientRef: String
        var ownerID: String
        var batchSize: Int
        var status: LenientSkillMixAssignmentStatus

        init(code: String, title: String, capacity: Int, unit: String, patientRef: String, ownerID: String, batchSize: Int, status: LenientSkillMixAssignmentStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.unit = unit
            self.patientRef = patientRef
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientSkillMixAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientSkillMixAssignmentStatus.warming || next == LenientSkillMixAssignmentStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientSkillMixAssignmentStatus.draining
            case .draining:
                return next == LenientSkillMixAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSkillMixAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient skill mix assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient skill mix assignment") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(batchSize) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> LenientSkillMixAssignment {
            return LenientSkillMixAssignment(
                code: code,
                title: title,
                capacity: capacity,
                unit: unit,
                patientRef: patientRef,
                ownerID: ownerID,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient skill mix assignment in status idle.
    static func newLenientSkillMixAssignment(_ code: String, title: String) -> LenientSkillMixAssignment {
        return LenientSkillMixAssignment(
            code: code,
            title: title,
            capacity: 0,
            unit: "",
            patientRef: "",
            ownerID: "",
            batchSize: 0,
            status: LenientSkillMixAssignmentStatus.idle
        )
    }
}
