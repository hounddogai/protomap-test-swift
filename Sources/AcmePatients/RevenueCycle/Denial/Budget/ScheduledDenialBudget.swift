import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled denial budget is in its life cycle.
    enum ScheduledDenialBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled denial budget, with what the planners need to act on it.
    final class ScheduledDenialBudget {
        var code: String
        var title: String
        var region: String
        var diagnosisCode: String
        var threshold: Double
        var channel: String
        var checksum: String
        var status: ScheduledDenialBudgetStatus

        init(code: String, title: String, region: String, diagnosisCode: String, threshold: Double, channel: String, checksum: String, status: ScheduledDenialBudgetStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.threshold = threshold
            self.channel = channel
            self.checksum = checksum
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

        func canMoveTo(_ next: ScheduledDenialBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledDenialBudgetStatus.running || next == ScheduledDenialBudgetStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledDenialBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledDenialBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled denial budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled denial budget") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> ScheduledDenialBudget {
            return ScheduledDenialBudget(
                code: code,
                title: title,
                region: region,
                diagnosisCode: diagnosisCode,
                threshold: threshold,
                channel: channel,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled denial budget in status new.
    static func newScheduledDenialBudget(_ code: String, title: String) -> ScheduledDenialBudget {
        return ScheduledDenialBudget(
            code: code,
            title: title,
            region: "",
            diagnosisCode: "",
            threshold: 0.0,
            channel: "",
            checksum: "",
            status: ScheduledDenialBudgetStatus.new
        )
    }
}
