import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary plan is in its life cycle.
    enum WeightedFormularyPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted formulary plan as the formulary team keeps it.
    final class WeightedFormularyPlan {
        var code: String
        var label: String
        var sequence: Int
        var payer: String
        var timezone: String
        var status: WeightedFormularyPlanStatus

        init(code: String, label: String, sequence: Int, payer: String, timezone: String, status: WeightedFormularyPlanStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.payer = payer
            self.timezone = timezone
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

        func canMoveTo(_ next: WeightedFormularyPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WeightedFormularyPlanStatus.done || next == WeightedFormularyPlanStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WeightedFormularyPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedFormularyPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted formulary plan") \(code)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> WeightedFormularyPlan {
            return WeightedFormularyPlan(
                code: code,
                label: label,
                sequence: sequence,
                payer: payer,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted formulary plan in status new.
    static func newWeightedFormularyPlan(_ code: String, label: String) -> WeightedFormularyPlan {
        return WeightedFormularyPlan(
            code: code,
            label: label,
            sequence: 0,
            payer: "",
            timezone: "",
            status: WeightedFormularyPlanStatus.new
        )
    }
}
