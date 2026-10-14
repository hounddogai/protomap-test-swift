import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped shift metric is in its life cycle.
    enum CappedShiftMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped shift metric, with what the planners need to act on it.
    final class CappedShiftMetric {
        var code: String
        var label: String
        var procedureCode: String
        var archived: Bool
        var sequence: Int
        var channel: String
        var currency: String
        var status: CappedShiftMetricStatus

        init(code: String, label: String, procedureCode: String, archived: Bool, sequence: Int, channel: String, currency: String, status: CappedShiftMetricStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.archived = archived
            self.sequence = sequence
            self.channel = channel
            self.currency = currency
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

        func canMoveTo(_ next: CappedShiftMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedShiftMetricStatus.inProgress || next == CappedShiftMetricStatus.cancelled
            case .scheduled:
                return next == CappedShiftMetricStatus.inProgress || next == CappedShiftMetricStatus.completed
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

        func moveTo(_ next: CappedShiftMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped shift metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> CappedShiftMetric {
            return CappedShiftMetric(
                code: code,
                label: label,
                procedureCode: procedureCode,
                archived: archived,
                sequence: sequence,
                channel: channel,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped shift metric in status planned.
    static func newCappedShiftMetric(_ code: String, label: String) -> CappedShiftMetric {
        return CappedShiftMetric(
            code: code,
            label: label,
            procedureCode: "",
            archived: false,
            sequence: 0,
            channel: "",
            currency: "",
            status: CappedShiftMetricStatus.planned
        )
    }
}
