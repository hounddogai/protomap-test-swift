import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted dispense metric is in its life cycle.
    enum WeightedDispenseMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted dispense metric as the dispense team keeps it.
    final class WeightedDispenseMetric {
        var code: String
        var name: String
        var procedureCode: String
        var archived: Bool
        var limit: Int
        var threshold: Double
        var status: WeightedDispenseMetricStatus

        init(code: String, name: String, procedureCode: String, archived: Bool, limit: Int, threshold: Double, status: WeightedDispenseMetricStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.archived = archived
            self.limit = limit
            self.threshold = threshold
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

        func canMoveTo(_ next: WeightedDispenseMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedDispenseMetricStatus.queued || next == WeightedDispenseMetricStatus.done
            case .queued:
                return next == WeightedDispenseMetricStatus.done || next == WeightedDispenseMetricStatus.failed
            case .running:
                return next == WeightedDispenseMetricStatus.done || next == WeightedDispenseMetricStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: WeightedDispenseMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted dispense metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return (Double(limit) * threshold * 100).rounded() / 100
        }

        func copyValue() -> WeightedDispenseMetric {
            return WeightedDispenseMetric(
                code: code,
                name: name,
                procedureCode: procedureCode,
                archived: archived,
                limit: limit,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted dispense metric in status new.
    static func newWeightedDispenseMetric(_ code: String, name: String) -> WeightedDispenseMetric {
        return WeightedDispenseMetric(
            code: code,
            name: name,
            procedureCode: "",
            archived: false,
            limit: 0,
            threshold: 0.0,
            status: WeightedDispenseMetricStatus.new
        )
    }
}
