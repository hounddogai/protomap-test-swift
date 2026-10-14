import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered assessment allocation is in its life cycle.
    enum TieredAssessmentAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered assessment allocation, with what the planners need to act on it.
    final class TieredAssessmentAllocation {
        var code: String
        var label: String
        var approved: Bool
        var tags: [String]
        var graceDays: Int
        var startsAt: Int
        var archived: Bool
        var priority: Int
        var status: TieredAssessmentAllocationStatus

        init(code: String, label: String, approved: Bool, tags: [String], graceDays: Int, startsAt: Int, archived: Bool, priority: Int, status: TieredAssessmentAllocationStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.tags = tags
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.archived = archived
            self.priority = priority
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

        func canMoveTo(_ next: TieredAssessmentAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredAssessmentAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered assessment allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((Double(graceDays) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredAssessmentAllocation {
            return TieredAssessmentAllocation(
                code: code,
                label: label,
                approved: approved,
                tags: tags,
                graceDays: graceDays,
                startsAt: startsAt,
                archived: archived,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered assessment allocation in status proposed.
    static func newTieredAssessmentAllocation(_ code: String, label: String) -> TieredAssessmentAllocation {
        return TieredAssessmentAllocation(
            code: code,
            label: label,
            approved: false,
            tags: [],
            graceDays: 0,
            startsAt: 0,
            archived: false,
            priority: 0,
            status: TieredAssessmentAllocationStatus.proposed
        )
    }
}
