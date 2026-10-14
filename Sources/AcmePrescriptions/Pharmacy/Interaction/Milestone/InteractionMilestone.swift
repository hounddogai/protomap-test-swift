import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction milestone is in its life cycle.
    enum InteractionMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One interaction milestone, with what the planners need to act on it.
    final class InteractionMilestone {
        var code: String
        var name: String
        var durationMinutes: Int
        var summary: String
        var createdAt: Int
        var archived: Bool
        var status: InteractionMilestoneStatus

        init(code: String, name: String, durationMinutes: Int, summary: String, createdAt: Int, archived: Bool, status: InteractionMilestoneStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.summary = summary
            self.createdAt = createdAt
            self.archived = archived
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

        func canMoveTo(_ next: InteractionMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == InteractionMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (Double(durationMinutes) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> InteractionMilestone {
            return InteractionMilestone(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                summary: summary,
                createdAt: createdAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction milestone in status draft.
    static func newInteractionMilestone(_ code: String, name: String) -> InteractionMilestone {
        return InteractionMilestone(
            code: code,
            name: name,
            durationMinutes: 0,
            summary: "",
            createdAt: 0,
            archived: false,
            status: InteractionMilestoneStatus.draft
        )
    }
}
