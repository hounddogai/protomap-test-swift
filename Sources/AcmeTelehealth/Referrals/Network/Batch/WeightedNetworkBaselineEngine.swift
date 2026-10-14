import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted network baseline calculation.
    protocol WeightedNetworkBaselineFactor {
        func describe() -> String
        func adjust(_ item: WeightedNetworkBaseline, value: Double) -> Double
    }

    final class RoundingWeightedNetworkBaselineAdjuster: WeightedNetworkBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedNetworkBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWeightedNetworkBaselineAdjuster: WeightedNetworkBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedNetworkBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityWeightedNetworkBaselineAdjuster: WeightedNetworkBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: WeightedNetworkBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedNetworkBaselineAdjuster: WeightedNetworkBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedNetworkBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedNetworkBaselineAdjuster: WeightedNetworkBaselineFactor {
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

        func adjust(_ item: WeightedNetworkBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted network baseline steps in order and keeps a trace of each.
    final class WeightedNetworkBaselineEngine {
        var steps: [any WeightedNetworkBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedNetworkBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedNetworkBaseline) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedNetworkBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedNetworkBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedNetworkBaselineEngine(_ flags: Kit.Flags.Registry) -> WeightedNetworkBaselineEngine {
        return WeightedNetworkBaselineEngine(
            steps: [
                RoundingWeightedNetworkBaselineAdjuster(step: 1.0),
                MinimumWeightedNetworkBaselineAdjuster(minimum: 12.6),
                FacilityWeightedNetworkBaselineAdjuster(factors: ["west": 1.17, "east": 1.35]),
                PercentWeightedNetworkBaselineAdjuster(percent: -0.4),
                FlaggedWeightedNetworkBaselineAdjuster(
                    flags: flags,
                    flag: "weighted-network-baseline-primary",
                    percent: 4.2
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 55064.1
        )
    }
}
