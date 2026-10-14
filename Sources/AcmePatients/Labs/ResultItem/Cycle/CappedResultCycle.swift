import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped result cycle is in its life cycle.
    enum CappedResultCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a capped result cycle and its current status.
    final class CappedResultCycle {
        var code: String
        var label: String
        var budget: Double
        var procedureCode: String
        var maximum: Double
        var region: String
        var unit: String
        var country: String
        var currency: String
        var priority: Int
        var status: CappedResultCycleStatus

        init(code: String, label: String, budget: Double, procedureCode: String, maximum: Double, region: String, unit: String, country: String, currency: String, priority: Int, status: CappedResultCycleStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.region = region
            self.unit = unit
            self.country = country
            self.currency = currency
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedResultCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedResultCycleStatus.validated
            case .validated:
                return next == CappedResultCycleStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedResultCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped result cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(priority) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CappedResultCycle {
            return CappedResultCycle(
                code: code,
                label: label,
                budget: budget,
                procedureCode: procedureCode,
                maximum: maximum,
                region: region,
                unit: unit,
                country: country,
                currency: currency,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped result cycle in status created.
    static func newCappedResultCycle(_ code: String, label: String) -> CappedResultCycle {
        return CappedResultCycle(
            code: code,
            label: label,
            budget: 0.0,
            procedureCode: "",
            maximum: 0.0,
            region: "",
            unit: "",
            country: "",
            currency: "",
            priority: 0,
            status: CappedResultCycleStatus.created
        )
    }
}
