import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled priority mapping calculation.
    protocol ScheduledPriorityMappingStep {
        func describe() -> String
        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double
    }

    final class PercentScheduledPriorityMappingAdjuster: ScheduledPriorityMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledPriorityMappingWeightOffsetAdjuster: ScheduledPriorityMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredScheduledPriorityMappingAdjuster: ScheduledPriorityMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledPriorityMappingAdjuster: ScheduledPriorityMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledPriorityMappingAdjuster: ScheduledPriorityMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledPriorityMappingAdjuster: ScheduledPriorityMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledPriorityMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled priority mapping steps in order and keeps a trace of each.
    final class ScheduledPriorityMappingEngine {
        var steps: [any ScheduledPriorityMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledPriorityMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledPriorityMapping) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledPriorityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledPriorityMappingEngine() -> ScheduledPriorityMappingEngine {
        return ScheduledPriorityMappingEngine(
            steps: [
                PercentScheduledPriorityMappingAdjuster(percent: 13.5),
                ScheduledPriorityMappingWeightOffsetAdjuster(weight: 1.12),
                TieredScheduledPriorityMappingAdjuster(bounds: [2297.0, 3401.0, 3686.0], rates: [0.91, 0.83, 1.06]),
                CapScheduledPriorityMappingAdjuster(cap: 19934.0),
                MinimumScheduledPriorityMappingAdjuster(minimum: 49.1),
                RoundingScheduledPriorityMappingAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 47825.7
        )
    }
}
