import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix draft is in its life cycle.
    enum SkillMixDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One skill mix draft, with what the planners need to act on it.
    final class SkillMixDraft {
        var code: String
        var name: String
        var quantity: Int
        var archived: Bool
        var cost: Double
        var segment: String
        var windowDays: Int
        var reviewer: String
        var graceDays: Int
        var approved: Bool
        var acuity: Int
        var status: SkillMixDraftStatus

        init(code: String, name: String, quantity: Int, archived: Bool, cost: Double, segment: String, windowDays: Int, reviewer: String, graceDays: Int, approved: Bool, acuity: Int, status: SkillMixDraftStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.archived = archived
            self.cost = cost
            self.segment = segment
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.graceDays = graceDays
            self.approved = approved
            self.acuity = acuity
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

        func canMoveTo(_ next: SkillMixDraftStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SkillMixDraftStatus.draining || next == SkillMixDraftStatus.stopped
            case .draining:
                return next == SkillMixDraftStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(acuity) + cost) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixDraft {
            return SkillMixDraft(
                code: code,
                name: name,
                quantity: quantity,
                archived: archived,
                cost: cost,
                segment: segment,
                windowDays: windowDays,
                reviewer: reviewer,
                graceDays: graceDays,
                approved: approved,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a skill mix draft in status idle.
    static func newSkillMixDraft(_ code: String, name: String) -> SkillMixDraft {
        return SkillMixDraft(
            code: code,
            name: name,
            quantity: 0,
            archived: false,
            cost: 0.0,
            segment: "",
            windowDays: 0,
            reviewer: "",
            graceDays: 0,
            approved: false,
            acuity: 0,
            status: SkillMixDraftStatus.idle
        )
    }
}
