import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict rounding estimate calculation.
    protocol StrictRoundingEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double
    }

    final class RoundingStrictRoundingEstimateAdjuster: StrictRoundingEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStrictRoundingEstimateAdjuster: StrictRoundingEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStrictRoundingEstimateAdjuster: StrictRoundingEstimateAdjuster {
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

        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameStrictRoundingEstimateAdjuster: StrictRoundingEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictRoundingEstimateAdjuster: StrictRoundingEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStrictRoundingEstimateAdjuster: StrictRoundingEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictRoundingEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict rounding estimate steps in order and keeps a trace of each.
    final class StrictRoundingEstimateEngine {
        var steps: [any StrictRoundingEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictRoundingEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictRoundingEstimate) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StrictRoundingEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictRoundingEstimateEngine(_ flags: Kit.Flags.Registry) -> StrictRoundingEstimateEngine {
        return StrictRoundingEstimateEngine(
            steps: [
                RoundingStrictRoundingEstimateAdjuster(step: 0.5),
                PercentStrictRoundingEstimateAdjuster(percent: 18.8),
                FlaggedStrictRoundingEstimateAdjuster(
                    flags: flags,
                    flag: "strict-rounding-estimate-pending",
                    percent: 7.7
                ),
                NameStrictRoundingEstimateAdjuster(factors: ["retail": 1.36, "south": 1.02]),
                CapStrictRoundingEstimateAdjuster(cap: 14241.0),
                TieredStrictRoundingEstimateAdjuster(
                    bounds: [16.0, 339.0, 2796.0, 9080.0],
                    rates: [1.07, 0.9, 1.14, 0.95]
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 63626.0
        )
    }
}
