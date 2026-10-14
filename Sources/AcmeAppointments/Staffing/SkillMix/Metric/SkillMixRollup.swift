import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix rollup is in its life cycle.
    enum SkillMixRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One skill mix rollup, with what the planners need to act on it.
    final class SkillMixRollup {
        var code: String
        var name: String
        var reviewer: String
        var version: Int
        var patientRef: String
        var status: SkillMixRollupStatus

        init(code: String, name: String, reviewer: String, version: Int, patientRef: String, status: SkillMixRollupStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.version = version
            self.patientRef = patientRef
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

        func canMoveTo(_ next: SkillMixRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SkillMixRollupStatus.draining || next == SkillMixRollupStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SkillMixRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("skill mix rollup") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> SkillMixRollup {
            return SkillMixRollup(
                code: code,
                name: name,
                reviewer: reviewer,
                version: version,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix rollup in status idle.
    static func newSkillMixRollup(_ code: String, name: String) -> SkillMixRollup {
        return SkillMixRollup(
            code: code,
            name: name,
            reviewer: "",
            version: 0,
            patientRef: "",
            status: SkillMixRollupStatus.idle
        )
    }
}
