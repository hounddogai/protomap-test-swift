import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped charge estimate calculation.
    protocol CappedChargeEstimateModifier {
        func describe() -> String
        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double
    }

    final class CapCappedChargeEstimateAdjuster: CappedChargeEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCappedChargeEstimateAdjuster: CappedChargeEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedChargeEstimateAdjuster: CappedChargeEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityCappedChargeEstimateAdjuster: CappedChargeEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedChargeEstimateDurationMinutesOffsetAdjuster: CappedChargeEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedCappedChargeEstimateAdjuster: CappedChargeEstimateModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: CappedChargeEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped charge estimate steps in order and keeps a trace of each.
    final class CappedChargeEstimateEngine {
        var steps: [any CappedChargeEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedChargeEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedChargeEstimate) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CappedChargeEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedChargeEstimateEngine(_ flags: Kit.Flags.Registry) -> CappedChargeEstimateEngine {
        return CappedChargeEstimateEngine(
            steps: [
                CapCappedChargeEstimateAdjuster(cap: 19266.0),
                PercentCappedChargeEstimateAdjuster(percent: 0.3),
                MinimumCappedChargeEstimateAdjuster(minimum: 40.0),
                FacilityCappedChargeEstimateAdjuster(factors: ["central": 1.22, "online": 1.19]),
                CappedChargeEstimateDurationMinutesOffsetAdjuster(weight: 1.94),
                FlaggedCappedChargeEstimateAdjuster(flags: flags, flag: "capped-charge-estimate-global", percent: 8.4),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 3707.6
        )
    }
}
