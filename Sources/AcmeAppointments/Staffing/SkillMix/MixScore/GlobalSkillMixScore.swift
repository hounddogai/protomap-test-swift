import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global skill mix score is in its life cycle.
    enum GlobalSkillMixScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One global skill mix score, with what the planners need to act on it.
    final class GlobalSkillMixScore {
        var code: String
        var name: String
        var capacity: Int
        var channel: String
        var diagnosisCode: String
        var windowDays: Int
        var copay: Double
        var score: Double
        var status: GlobalSkillMixScoreStatus

        init(code: String, name: String, capacity: Int, channel: String, diagnosisCode: String, windowDays: Int, copay: Double, score: Double, status: GlobalSkillMixScoreStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.windowDays = windowDays
            self.copay = copay
            self.score = score
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

        func canMoveTo(_ next: GlobalSkillMixScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalSkillMixScoreStatus.inProgress || next == GlobalSkillMixScoreStatus.completed
            case .inProgress:
                return next == GlobalSkillMixScoreStatus.completed || next == GlobalSkillMixScoreStatus.cancelled
            case .completed:
                return next == GlobalSkillMixScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSkillMixScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global skill mix score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(windowDays) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSkillMixScore {
            return GlobalSkillMixScore(
                code: code,
                name: name,
                capacity: capacity,
                channel: channel,
                diagnosisCode: diagnosisCode,
                windowDays: windowDays,
                copay: copay,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global skill mix score in status planned.
    static func newGlobalSkillMixScore(_ code: String, name: String) -> GlobalSkillMixScore {
        return GlobalSkillMixScore(
            code: code,
            name: name,
            capacity: 0,
            channel: "",
            diagnosisCode: "",
            windowDays: 0,
            copay: 0.0,
            score: 0.0,
            status: GlobalSkillMixScoreStatus.planned
        )
    }
}
