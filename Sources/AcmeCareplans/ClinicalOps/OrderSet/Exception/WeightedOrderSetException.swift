import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted order set exception is in its life cycle.
    enum WeightedOrderSetExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a weighted order set exception and its current status.
    final class WeightedOrderSetException {
        var code: String
        var label: String
        var margin: Double
        var unit: String
        var graceDays: Int
        var reviewer: String
        var status: WeightedOrderSetExceptionStatus

        init(code: String, label: String, margin: Double, unit: String, graceDays: Int, reviewer: String, status: WeightedOrderSetExceptionStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.unit = unit
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedOrderSetExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedOrderSetExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedOrderSetExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted order set exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return ((margin + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOrderSetException {
            return WeightedOrderSetException(
                code: code,
                label: label,
                margin: margin,
                unit: unit,
                graceDays: graceDays,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted order set exception in status proposed.
    static func newWeightedOrderSetException(_ code: String, label: String) -> WeightedOrderSetException {
        return WeightedOrderSetException(
            code: code,
            label: label,
            margin: 0.0,
            unit: "",
            graceDays: 0,
            reviewer: "",
            status: WeightedOrderSetExceptionStatus.proposed
        )
    }
}
