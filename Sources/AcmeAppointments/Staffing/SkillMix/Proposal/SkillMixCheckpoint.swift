import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix checkpoint is in its life cycle.
    enum SkillMixCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One skill mix checkpoint, with what the planners need to act on it.
    final class SkillMixCheckpoint {
        var code: String
        var title: String
        var reviewer: String
        var dosageMg: Double
        var threshold: Double
        var channel: String
        var durationMinutes: Int
        var ward: String
        var procedureCode: String
        var refills: Int
        var copay: Double
        var status: SkillMixCheckpointStatus

        init(code: String, title: String, reviewer: String, dosageMg: Double, threshold: Double, channel: String, durationMinutes: Int, ward: String, procedureCode: String, refills: Int, copay: Double, status: SkillMixCheckpointStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.channel = channel
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.procedureCode = procedureCode
            self.refills = refills
            self.copay = copay
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

        func canMoveTo(_ next: SkillMixCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == SkillMixCheckpointStatus.scheduled
            case .scheduled:
                return next == SkillMixCheckpointStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SkillMixCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((copay - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixCheckpoint {
            return SkillMixCheckpoint(
                code: code,
                title: title,
                reviewer: reviewer,
                dosageMg: dosageMg,
                threshold: threshold,
                channel: channel,
                durationMinutes: durationMinutes,
                ward: ward,
                procedureCode: procedureCode,
                refills: refills,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a skill mix checkpoint in status planned.
    static func newSkillMixCheckpoint(_ code: String, title: String) -> SkillMixCheckpoint {
        return SkillMixCheckpoint(
            code: code,
            title: title,
            reviewer: "",
            dosageMg: 0.0,
            threshold: 0.0,
            channel: "",
            durationMinutes: 0,
            ward: "",
            procedureCode: "",
            refills: 0,
            copay: 0.0,
            status: SkillMixCheckpointStatus.planned
        )
    }
}
