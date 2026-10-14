import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback priority group calculation.
    protocol FallbackPriorityGroupStep {
        func describe() -> String
        func adjust(_ item: FallbackPriorityGroup, value: Double) -> Double
    }

    final class RoundingFallbackPriorityGroupAdjuster: FallbackPriorityGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackPriorityGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryFallbackPriorityGroupAdjuster: FallbackPriorityGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FallbackPriorityGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFallbackPriorityGroupAdjuster: FallbackPriorityGroupStep {
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

        func adjust(_ item: FallbackPriorityGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackPriorityGroupAdjuster: FallbackPriorityGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackPriorityGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback priority group steps in order and keeps a trace of each.
    final class FallbackPriorityGroupEngine {
        var steps: [any FallbackPriorityGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackPriorityGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackPriorityGroup) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackPriorityGroupStep = steps[index]
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

        func evaluateAll(_ items: [FallbackPriorityGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackPriorityGroupEngine(_ flags: Kit.Flags.Registry) -> FallbackPriorityGroupEngine {
        return FallbackPriorityGroupEngine(
            steps: [
                RoundingFallbackPriorityGroupAdjuster(step: 5.0),
                CategoryFallbackPriorityGroupAdjuster(factors: ["north": 1.2, "west": 0.95, "online": 1.35]),
                FlaggedFallbackPriorityGroupAdjuster(
                    flags: flags,
                    flag: "fallback-priority-group-fallback",
                    percent: 7.7
                ),
                TieredFallbackPriorityGroupAdjuster(bounds: [1626.0, 9942.0], rates: [1.07, 0.89]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 97786.1
        )
    }
}
