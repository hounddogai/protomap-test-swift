import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement schedule is in its life cycle.
    enum AdaptiveStatementScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive statement schedule as the statement team keeps it.
    final class AdaptiveStatementSchedule {
        var code: String
        var label: String
        var capacity: Int
        var allergy: String
        var summary: String
        var maximum: Double
        var status: AdaptiveStatementScheduleStatus

        init(code: String, label: String, capacity: Int, allergy: String, summary: String, maximum: Double, status: AdaptiveStatementScheduleStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.allergy = allergy
            self.summary = summary
            self.maximum = maximum
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

        func canMoveTo(_ next: AdaptiveStatementScheduleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AdaptiveStatementScheduleStatus.running || next == AdaptiveStatementScheduleStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AdaptiveStatementScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveStatementScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(capacity) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStatementSchedule {
            return AdaptiveStatementSchedule(
                code: code,
                label: label,
                capacity: capacity,
                allergy: allergy,
                summary: summary,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive statement schedule in status new.
    static func newAdaptiveStatementSchedule(_ code: String, label: String) -> AdaptiveStatementSchedule {
        return AdaptiveStatementSchedule(
            code: code,
            label: label,
            capacity: 0,
            allergy: "",
            summary: "",
            maximum: 0.0,
            status: AdaptiveStatementScheduleStatus.new
        )
    }
}
