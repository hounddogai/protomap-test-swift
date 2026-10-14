import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted discharge plan summary is in its life cycle.
    enum WeightedDischargePlanSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted discharge plan summary and its current status.
    final class WeightedDischargePlanSummary {
        var code: String
        var name: String
        var attempts: Int
        var payer: String
        var dosageMg: Double
        var threshold: Double
        var status: WeightedDischargePlanSummaryStatus

        init(code: String, name: String, attempts: Int, payer: String, dosageMg: Double, threshold: Double, status: WeightedDischargePlanSummaryStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.payer = payer
            self.dosageMg = dosageMg
            self.threshold = threshold
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

        func canMoveTo(_ next: WeightedDischargePlanSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: WeightedDischargePlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted discharge plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return ((Double(attempts) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDischargePlanSummary {
            return WeightedDischargePlanSummary(
                code: code,
                name: name,
                attempts: attempts,
                payer: payer,
                dosageMg: dosageMg,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted discharge plan summary in status idle.
    static func newWeightedDischargePlanSummary(_ code: String, name: String) -> WeightedDischargePlanSummary {
        return WeightedDischargePlanSummary(
            code: code,
            name: name,
            attempts: 0,
            payer: "",
            dosageMg: 0.0,
            threshold: 0.0,
            status: WeightedDischargePlanSummaryStatus.idle
        )
    }
}
