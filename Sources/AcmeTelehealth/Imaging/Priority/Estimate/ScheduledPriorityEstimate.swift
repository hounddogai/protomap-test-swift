import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled priority estimate is in its life cycle.
    enum ScheduledPriorityEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a scheduled priority estimate and its current status.
    final class ScheduledPriorityEstimate {
        var code: String
        var title: String
        var weight: Double
        var diagnosisCode: String
        var ceiling: Double
        var status: ScheduledPriorityEstimateStatus

        init(code: String, title: String, weight: Double, diagnosisCode: String, ceiling: Double, status: ScheduledPriorityEstimateStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ScheduledPriorityEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledPriorityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled priority estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return (weight * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPriorityEstimate {
            return ScheduledPriorityEstimate(
                code: code,
                title: title,
                weight: weight,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled priority estimate in status planned.
    static func newScheduledPriorityEstimate(_ code: String, title: String) -> ScheduledPriorityEstimate {
        return ScheduledPriorityEstimate(
            code: code,
            title: title,
            weight: 0.0,
            diagnosisCode: "",
            ceiling: 0.0,
            status: ScheduledPriorityEstimateStatus.planned
        )
    }
}
