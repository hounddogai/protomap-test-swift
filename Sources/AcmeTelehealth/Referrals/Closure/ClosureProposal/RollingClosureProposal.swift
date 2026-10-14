import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling closure proposal is in its life cycle.
    enum RollingClosureProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling closure proposal as the closure team keeps it.
    final class RollingClosureProposal {
        var code: String
        var label: String
        var reviewer: String
        var score: Double
        var limit: Int
        var pinned: Bool
        var rate: Double
        var archived: Bool
        var visible: Bool
        var unit: String
        var allergy: String
        var status: RollingClosureProposalStatus

        init(code: String, label: String, reviewer: String, score: Double, limit: Int, pinned: Bool, rate: Double, archived: Bool, visible: Bool, unit: String, allergy: String, status: RollingClosureProposalStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.score = score
            self.limit = limit
            self.pinned = pinned
            self.rate = rate
            self.archived = archived
            self.visible = visible
            self.unit = unit
            self.allergy = allergy
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

        func canMoveTo(_ next: RollingClosureProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingClosureProposalStatus.resolved || next == RollingClosureProposalStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RollingClosureProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling closure proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedTotal() -> Double {
            return ((Double(limit) - score) * 100).rounded() / 100
        }

        func copyValue() -> RollingClosureProposal {
            return RollingClosureProposal(
                code: code,
                label: label,
                reviewer: reviewer,
                score: score,
                limit: limit,
                pinned: pinned,
                rate: rate,
                archived: archived,
                visible: visible,
                unit: unit,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling closure proposal in status open.
    static func newRollingClosureProposal(_ code: String, label: String) -> RollingClosureProposal {
        return RollingClosureProposal(
            code: code,
            label: label,
            reviewer: "",
            score: 0.0,
            limit: 0,
            pinned: false,
            rate: 0.0,
            archived: false,
            visible: false,
            unit: "",
            allergy: "",
            status: RollingClosureProposalStatus.`open`
        )
    }
}
