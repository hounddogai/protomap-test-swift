import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan milestone is in its life cycle.
    enum AcuityPlanMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a acuity plan milestone and its current status.
    final class AcuityPlanMilestone {
        var code: String
        var label: String
        var ownerID: String
        var score: Double
        var rate: Double
        var status: AcuityPlanMilestoneStatus

        init(code: String, label: String, ownerID: String, score: Double, rate: Double, status: AcuityPlanMilestoneStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.score = score
            self.rate = rate
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

        func canMoveTo(_ next: AcuityPlanMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == AcuityPlanMilestoneStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AcuityPlanMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((score + rate) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanMilestone {
            return AcuityPlanMilestone(
                code: code,
                label: label,
                ownerID: ownerID,
                score: score,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan milestone in status idle.
    static func newAcuityPlanMilestone(_ code: String, label: String) -> AcuityPlanMilestone {
        return AcuityPlanMilestone(
            code: code,
            label: label,
            ownerID: "",
            score: 0.0,
            rate: 0.0,
            status: AcuityPlanMilestoneStatus.idle
        )
    }
}
