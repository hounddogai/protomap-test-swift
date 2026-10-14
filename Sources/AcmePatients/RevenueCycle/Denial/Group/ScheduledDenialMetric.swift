import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled denial metric is in its life cycle.
    enum ScheduledDenialMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One scheduled denial metric, with what the planners need to act on it.
    final class ScheduledDenialMetric {
        var code: String
        var title: String
        var batchSize: Int
        var score: Double
        var description: String
        var copay: Double
        var clinicianID: String
        var graceDays: Int
        var status: ScheduledDenialMetricStatus

        init(code: String, title: String, batchSize: Int, score: Double, description: String, copay: Double, clinicianID: String, graceDays: Int, status: ScheduledDenialMetricStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.score = score
            self.description = description
            self.copay = copay
            self.clinicianID = clinicianID
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ScheduledDenialMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledDenialMetricStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: ScheduledDenialMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled denial metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveTotal() -> Double {
            return ((Double(batchSize) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledDenialMetric {
            return ScheduledDenialMetric(
                code: code,
                title: title,
                batchSize: batchSize,
                score: score,
                description: description,
                copay: copay,
                clinicianID: clinicianID,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled denial metric in status planned.
    static func newScheduledDenialMetric(_ code: String, title: String) -> ScheduledDenialMetric {
        return ScheduledDenialMetric(
            code: code,
            title: title,
            batchSize: 0,
            score: 0.0,
            description: "",
            copay: 0.0,
            clinicianID: "",
            graceDays: 0,
            status: ScheduledDenialMetricStatus.planned
        )
    }
}
