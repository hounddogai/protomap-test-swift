import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled cleaning plan is in its life cycle.
    enum ScheduledCleaningPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled cleaning plan and its current status.
    final class ScheduledCleaningPlan {
        var code: String
        var title: String
        var limit: Int
        var budget: Double
        var segment: String
        var maximum: Double
        var specialty: String
        var weight: Double
        var status: ScheduledCleaningPlanStatus

        init(code: String, title: String, limit: Int, budget: Double, segment: String, maximum: Double, specialty: String, weight: Double, status: ScheduledCleaningPlanStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.budget = budget
            self.segment = segment
            self.maximum = maximum
            self.specialty = specialty
            self.weight = weight
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

        func canMoveTo(_ next: ScheduledCleaningPlanStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledCleaningPlanStatus.warming || next == ScheduledCleaningPlanStatus.ready
            case .warming:
                return next == ScheduledCleaningPlanStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledCleaningPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled cleaning plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled cleaning plan") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(limit) * budget * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCleaningPlan {
            return ScheduledCleaningPlan(
                code: code,
                title: title,
                limit: limit,
                budget: budget,
                segment: segment,
                maximum: maximum,
                specialty: specialty,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled cleaning plan in status idle.
    static func newScheduledCleaningPlan(_ code: String, title: String) -> ScheduledCleaningPlan {
        return ScheduledCleaningPlan(
            code: code,
            title: title,
            limit: 0,
            budget: 0.0,
            segment: "",
            maximum: 0.0,
            specialty: "",
            weight: 0.0,
            status: ScheduledCleaningPlanStatus.idle
        )
    }
}
