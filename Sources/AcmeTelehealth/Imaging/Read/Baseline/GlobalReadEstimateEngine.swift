import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global read estimate calculation.
    protocol GlobalReadEstimateModifier {
        func describe() -> String
        func adjust(_ item: GlobalReadEstimate, value: Double) -> Double
    }

    final class GlobalReadEstimateDiscountOffsetAdjuster: GlobalReadEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: GlobalReadEstimate, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingGlobalReadEstimateAdjuster: GlobalReadEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalReadEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelGlobalReadEstimateAdjuster: GlobalReadEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalReadEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalReadEstimateAdjuster: GlobalReadEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalReadEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalReadEstimateAdjuster: GlobalReadEstimateModifier {
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

        func adjust(_ item: GlobalReadEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global read estimate steps in order and keeps a trace of each.
    final class GlobalReadEstimateEngine {
        var steps: [any GlobalReadEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReadEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalReadEstimate) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [GlobalReadEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalReadEstimateEngine(_ flags: Kit.Flags.Registry) -> GlobalReadEstimateEngine {
        return GlobalReadEstimateEngine(
            steps: [
                GlobalReadEstimateDiscountOffsetAdjuster(weight: 0.51),
                RoundingGlobalReadEstimateAdjuster(step: 5.0),
                LabelGlobalReadEstimateAdjuster(factors: ["retail": 1.24, "west": 1.06, "south": 1.11]),
                CapGlobalReadEstimateAdjuster(cap: 42960.0),
                FlaggedGlobalReadEstimateAdjuster(flags: flags, flag: "global-read-estimate-lenient", percent: 5.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 14941.6
        )
    }
}
