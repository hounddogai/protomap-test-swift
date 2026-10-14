import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary float pool milestone is in its life cycle.
    enum PrimaryFloatPoolMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One primary float pool milestone, with what the planners need to act on it.
    final class PrimaryFloatPoolMilestone {
        var code: String
        var label: String
        var category: String
        var reviewer: String
        var refills: Int
        var attempts: Int
        var ratio: Double
        var facility: String
        var unit: String
        var rate: Double
        var status: PrimaryFloatPoolMilestoneStatus

        init(code: String, label: String, category: String, reviewer: String, refills: Int, attempts: Int, ratio: Double, facility: String, unit: String, rate: Double, status: PrimaryFloatPoolMilestoneStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.reviewer = reviewer
            self.refills = refills
            self.attempts = attempts
            self.ratio = ratio
            self.facility = facility
            self.unit = unit
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryFloatPoolMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PrimaryFloatPoolMilestoneStatus.done
            case .done:
                return next == PrimaryFloatPoolMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryFloatPoolMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary float pool milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary float pool milestone") \(code)"
        }

        func weightedLoad() -> Double {
            return (rate * ratio * 100).rounded() / 100
        }

        func copyValue() -> PrimaryFloatPoolMilestone {
            return PrimaryFloatPoolMilestone(
                code: code,
                label: label,
                category: category,
                reviewer: reviewer,
                refills: refills,
                attempts: attempts,
                ratio: ratio,
                facility: facility,
                unit: unit,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary float pool milestone in status new.
    static func newPrimaryFloatPoolMilestone(_ code: String, label: String) -> PrimaryFloatPoolMilestone {
        return PrimaryFloatPoolMilestone(
            code: code,
            label: label,
            category: "",
            reviewer: "",
            refills: 0,
            attempts: 0,
            ratio: 0.0,
            facility: "",
            unit: "",
            rate: 0.0,
            status: PrimaryFloatPoolMilestoneStatus.new
        )
    }
}
