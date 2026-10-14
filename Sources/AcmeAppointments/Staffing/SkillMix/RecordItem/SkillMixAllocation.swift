import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix allocation is in its life cycle.
    enum SkillMixAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One skill mix allocation, with what the planners need to act on it.
    final class SkillMixAllocation {
        var code: String
        var name: String
        var ceiling: Double
        var notes: String
        var startsAt: Int
        var status: SkillMixAllocationStatus

        init(code: String, name: String, ceiling: Double, notes: String, startsAt: Int, status: SkillMixAllocationStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.notes = notes
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SkillMixAllocationStatus.active || next == SkillMixAllocationStatus.closed
            case .active:
                return next == SkillMixAllocationStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SkillMixAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("skill mix allocation") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(startsAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> SkillMixAllocation {
            return SkillMixAllocation(
                code: code,
                name: name,
                ceiling: ceiling,
                notes: notes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix allocation in status draft.
    static func newSkillMixAllocation(_ code: String, name: String) -> SkillMixAllocation {
        return SkillMixAllocation(
            code: code,
            name: name,
            ceiling: 0.0,
            notes: "",
            startsAt: 0,
            status: SkillMixAllocationStatus.draft
        )
    }
}
