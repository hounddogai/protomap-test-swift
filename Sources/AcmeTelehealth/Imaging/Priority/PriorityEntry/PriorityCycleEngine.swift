import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority cycle calculation.
    protocol PriorityCycleStep {
        func describe() -> String
        func adjust(_ item: PriorityCycle, value: Double) -> Double
    }

    final class UnitPriorityCycleAdjuster: PriorityCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PriorityCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPriorityCycleAdjuster: PriorityCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPriorityCycleAdjuster: PriorityCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPriorityCycleAdjuster: PriorityCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPriorityCycleAdjuster: PriorityCycleStep {
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

        func adjust(_ item: PriorityCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPriorityCycleAdjuster: PriorityCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority cycle steps in order and keeps a trace of each.
    final class PriorityCycleEngine {
        var steps: [any PriorityCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PriorityCycle) -> Double {
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

        func evaluateAll(_ items: [PriorityCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPriorityCycleEngine(_ flags: Kit.Flags.Registry) -> PriorityCycleEngine {
        return PriorityCycleEngine(
            steps: [
                UnitPriorityCycleAdjuster(factors: ["central": 1.03]),
                TieredPriorityCycleAdjuster(bounds: [7548.0, 8490.0], rates: [1.11, 1.01]),
                CapPriorityCycleAdjuster(cap: 47883.0),
                RoundingPriorityCycleAdjuster(step: 5.0),
                FlaggedPriorityCycleAdjuster(flags: flags, flag: "priority-cycle-lenient", percent: -6.0),
                PercentPriorityCycleAdjuster(percent: 18.7),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 16326.5
        )
    }
}
