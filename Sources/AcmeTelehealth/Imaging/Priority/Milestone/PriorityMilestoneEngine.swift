import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority milestone calculation.
    protocol PriorityMilestoneStep {
        func describe() -> String
        func adjust(_ item: PriorityMilestone, value: Double) -> Double
    }

    final class FlaggedPriorityMilestoneAdjuster: PriorityMilestoneStep {
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

        func adjust(_ item: PriorityMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPriorityMilestoneAdjuster: PriorityMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocalePriorityMilestoneAdjuster: PriorityMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PriorityMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPriorityMilestoneAdjuster: PriorityMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPriorityMilestoneAdjuster: PriorityMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPriorityMilestoneAdjuster: PriorityMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the priority milestone steps in order and keeps a trace of each.
    final class PriorityMilestoneEngine {
        var steps: [any PriorityMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityMilestone) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [PriorityMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityMilestoneEngine(_ flags: Kit.Flags.Registry) -> PriorityMilestoneEngine {
        return PriorityMilestoneEngine(
            steps: [
                FlaggedPriorityMilestoneAdjuster(flags: flags, flag: "priority-milestone-manual", percent: 1.0),
                CapPriorityMilestoneAdjuster(cap: 30066.0),
                LocalePriorityMilestoneAdjuster(factors: ["west": 0.99, "east": 1.02, "south": 1.03]),
                MinimumPriorityMilestoneAdjuster(minimum: 41.0),
                RoundingPriorityMilestoneAdjuster(step: 0.05),
                TieredPriorityMilestoneAdjuster(
                    bounds: [163.0, 4240.0, 8560.0, 9413.0],
                    rates: [1.12, 1.18, 0.89, 1.01]
                ),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 55932.6
        )
    }
}
