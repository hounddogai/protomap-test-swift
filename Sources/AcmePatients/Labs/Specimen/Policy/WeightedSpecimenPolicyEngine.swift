import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted specimen policy calculation.
    protocol WeightedSpecimenPolicyModifier {
        func describe() -> String
        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double
    }

    final class FlaggedWeightedSpecimenPolicyAdjuster: WeightedSpecimenPolicyModifier {
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

        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedSpecimenPolicyAdjuster: WeightedSpecimenPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedSpecimenPolicyAdjuster: WeightedSpecimenPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedSpecimenPolicyAdjuster: WeightedSpecimenPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedSpecimenPolicyAdjuster: WeightedSpecimenPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedSpecimenPolicyAdjuster: WeightedSpecimenPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSpecimenPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted specimen policy steps in order and keeps a trace of each.
    final class WeightedSpecimenPolicyEngine {
        var steps: [any WeightedSpecimenPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSpecimenPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedSpecimenPolicy) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSpecimenPolicyModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedSpecimenPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedSpecimenPolicyEngine(_ flags: Kit.Flags.Registry) -> WeightedSpecimenPolicyEngine {
        return WeightedSpecimenPolicyEngine(
            steps: [
                FlaggedWeightedSpecimenPolicyAdjuster(
                    flags: flags,
                    flag: "weighted-specimen-policy-adaptive",
                    percent: -6.4
                ),
                CapWeightedSpecimenPolicyAdjuster(cap: 18526.0),
                PercentWeightedSpecimenPolicyAdjuster(percent: 16.0),
                MinimumWeightedSpecimenPolicyAdjuster(minimum: 37.3),
                TieredWeightedSpecimenPolicyAdjuster(bounds: [1059.0, 7331.0], rates: [0.97, 1.06]),
                RoundingWeightedSpecimenPolicyAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 29061.1
        )
    }
}
