import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix assignment is in its life cycle.
    enum SkillMixAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A skill mix assignment as the skill mix team keeps it.
    final class SkillMixAssignment {
        var code: String
        var name: String
        var capacity: Int
        var reviewer: String
        var ward: String
        var visitMinutes: Int
        var status: SkillMixAssignmentStatus

        init(code: String, name: String, capacity: Int, reviewer: String, ward: String, visitMinutes: Int, status: SkillMixAssignmentStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.reviewer = reviewer
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == SkillMixAssignmentStatus.retired
            case .validated:
                return next == SkillMixAssignmentStatus.published || next == SkillMixAssignmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SkillMixAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(visitMinutes) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixAssignment {
            return SkillMixAssignment(
                code: code,
                name: name,
                capacity: capacity,
                reviewer: reviewer,
                ward: ward,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a skill mix assignment in status created.
    static func newSkillMixAssignment(_ code: String, name: String) -> SkillMixAssignment {
        return SkillMixAssignment(
            code: code,
            name: name,
            capacity: 0,
            reviewer: "",
            ward: "",
            visitMinutes: 0,
            status: SkillMixAssignmentStatus.created
        )
    }
}
