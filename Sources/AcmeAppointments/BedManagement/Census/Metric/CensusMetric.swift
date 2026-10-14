import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census metric is in its life cycle.
    enum CensusMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One census metric, with what the planners need to act on it.
    final class CensusMetric {
        var code: String
        var name: String
        var facility: String
        var quantity: Int
        var reviewer: String
        var source: String
        var amount: Double
        var sequence: Int
        var status: CensusMetricStatus

        init(code: String, name: String, facility: String, quantity: Int, reviewer: String, source: String, amount: Double, sequence: Int, status: CensusMetricStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.quantity = quantity
            self.reviewer = reviewer
            self.source = source
            self.amount = amount
            self.sequence = sequence
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

        func canMoveTo(_ next: CensusMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == CensusMetricStatus.completed || next == CensusMetricStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CensusMetricStatus.cancelled
            case .completed:
                return next == CensusMetricStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return (amount * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> CensusMetric {
            return CensusMetric(
                code: code,
                name: name,
                facility: facility,
                quantity: quantity,
                reviewer: reviewer,
                source: source,
                amount: amount,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a census metric in status planned.
    static func newCensusMetric(_ code: String, name: String) -> CensusMetric {
        return CensusMetric(
            code: code,
            name: name,
            facility: "",
            quantity: 0,
            reviewer: "",
            source: "",
            amount: 0.0,
            sequence: 0,
            status: CensusMetricStatus.planned
        )
    }
}
