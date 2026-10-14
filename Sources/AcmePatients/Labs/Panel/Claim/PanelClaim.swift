import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel claim is in its life cycle.
    enum PanelClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One panel claim, with what the planners need to act on it.
    final class PanelClaim {
        var code: String
        var label: String
        var phone: String
        var summary: String
        var score: Double
        var reviewer: String
        var status: PanelClaimStatus

        init(code: String, label: String, phone: String, summary: String, score: Double, reviewer: String, status: PanelClaimStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.summary = summary
            self.score = score
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PanelClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == PanelClaimStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PanelClaimStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PanelClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("panel claim") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PanelClaim {
            return PanelClaim(
                code: code,
                label: label,
                phone: phone,
                summary: summary,
                score: score,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel claim in status planned.
    static func newPanelClaim(_ code: String, label: String) -> PanelClaim {
        return PanelClaim(
            code: code,
            label: label,
            phone: "",
            summary: "",
            score: 0.0,
            reviewer: "",
            status: PanelClaimStatus.planned
        )
    }
}
