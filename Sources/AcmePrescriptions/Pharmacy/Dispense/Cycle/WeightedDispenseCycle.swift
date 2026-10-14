import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted dispense cycle is in its life cycle.
    enum WeightedDispenseCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a weighted dispense cycle and its current status.
    final class WeightedDispenseCycle {
        var code: String
        var title: String
        var visitMinutes: Int
        var label: String
        var budget: Double
        var ownerID: String
        var rate: Double
        var reviewer: String
        var acuity: Int
        var ratio: Double
        var channel: String
        var status: WeightedDispenseCycleStatus

        init(code: String, title: String, visitMinutes: Int, label: String, budget: Double, ownerID: String, rate: Double, reviewer: String, acuity: Int, ratio: Double, channel: String, status: WeightedDispenseCycleStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.label = label
            self.budget = budget
            self.ownerID = ownerID
            self.rate = rate
            self.reviewer = reviewer
            self.acuity = acuity
            self.ratio = ratio
            self.channel = channel
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

        func canMoveTo(_ next: WeightedDispenseCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedDispenseCycleStatus.inReview || next == WeightedDispenseCycleStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedDispenseCycleStatus.reopened || next == WeightedDispenseCycleStatus.archived
            case .reopened:
                return next == WeightedDispenseCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedDispenseCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted dispense cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((budget - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDispenseCycle {
            return WeightedDispenseCycle(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                label: label,
                budget: budget,
                ownerID: ownerID,
                rate: rate,
                reviewer: reviewer,
                acuity: acuity,
                ratio: ratio,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted dispense cycle in status open.
    static func newWeightedDispenseCycle(_ code: String, title: String) -> WeightedDispenseCycle {
        return WeightedDispenseCycle(
            code: code,
            title: title,
            visitMinutes: 0,
            label: "",
            budget: 0.0,
            ownerID: "",
            rate: 0.0,
            reviewer: "",
            acuity: 0,
            ratio: 0.0,
            channel: "",
            status: WeightedDispenseCycleStatus.`open`
        )
    }
}
