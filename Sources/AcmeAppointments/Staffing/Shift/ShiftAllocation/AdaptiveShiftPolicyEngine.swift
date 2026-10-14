import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive shift policy calculation.
    protocol AdaptiveShiftPolicyStep {
        func describe() -> String
        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double
    }

    final class FlaggedAdaptiveShiftPolicyAdjuster: AdaptiveShiftPolicyStep {
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

        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveShiftPolicyAdjuster: AdaptiveShiftPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveShiftPolicyAdjuster: AdaptiveShiftPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveShiftPolicyAdjuster: AdaptiveShiftPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAdaptiveShiftPolicyAdjuster: AdaptiveShiftPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameAdaptiveShiftPolicyAdjuster: AdaptiveShiftPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveShiftPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive shift policy steps in order and keeps a trace of each.
    final class AdaptiveShiftPolicyEngine {
        var steps: [any AdaptiveShiftPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveShiftPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveShiftPolicy) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveShiftPolicyStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AdaptiveShiftPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveShiftPolicyEngine(_ flags: Kit.Flags.Registry) -> AdaptiveShiftPolicyEngine {
        return AdaptiveShiftPolicyEngine(
            steps: [
                FlaggedAdaptiveShiftPolicyAdjuster(flags: flags, flag: "adaptive-shift-policy-tiered", percent: -9.7),
                TieredAdaptiveShiftPolicyAdjuster(
                    bounds: [4144.0, 9427.0, 9652.0, 9794.0],
                    rates: [1.18, 1.14, 0.87, 0.84]
                ),
                CapAdaptiveShiftPolicyAdjuster(cap: 9613.0),
                MinimumAdaptiveShiftPolicyAdjuster(minimum: 33.8),
                RoundingAdaptiveShiftPolicyAdjuster(step: 5.0),
                NameAdaptiveShiftPolicyAdjuster(factors: ["central": 0.83, "south": 1.04]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 11930.0
        )
    }
}
