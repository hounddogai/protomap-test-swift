import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal handoff milestone is in its life cycle.
    enum SeasonalHandoffMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal handoff milestone, with what the planners need to act on it.
    final class SeasonalHandoffMilestone {
        var code: String
        var label: String
        var score: Double
        var startsAt: Int
        var dosageMg: Double
        var capacity: Int
        var phone: String
        var archived: Bool
        var status: SeasonalHandoffMilestoneStatus

        init(code: String, label: String, score: Double, startsAt: Int, dosageMg: Double, capacity: Int, phone: String, archived: Bool, status: SeasonalHandoffMilestoneStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.phone = phone
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalHandoffMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == SeasonalHandoffMilestoneStatus.reopened || next == SeasonalHandoffMilestoneStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalHandoffMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalHandoffMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal handoff milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal handoff milestone") \(code)"
        }

        func netTotal() -> Double {
            return ((dosageMg + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalHandoffMilestone {
            return SeasonalHandoffMilestone(
                code: code,
                label: label,
                score: score,
                startsAt: startsAt,
                dosageMg: dosageMg,
                capacity: capacity,
                phone: phone,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal handoff milestone in status open.
    static func newSeasonalHandoffMilestone(_ code: String, label: String) -> SeasonalHandoffMilestone {
        return SeasonalHandoffMilestone(
            code: code,
            label: label,
            score: 0.0,
            startsAt: 0,
            dosageMg: 0.0,
            capacity: 0,
            phone: "",
            archived: false,
            status: SeasonalHandoffMilestoneStatus.`open`
        )
    }
}
