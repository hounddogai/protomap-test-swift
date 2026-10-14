import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional priority cycle calculation.
    protocol RegionalPriorityCycleFactor {
        func describe() -> String
        func adjust(_ item: RegionalPriorityCycle, value: Double) -> Double
    }

    final class CapRegionalPriorityCycleAdjuster: RegionalPriorityCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalPriorityCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalPriorityCycleCapacityOffsetAdjuster: RegionalPriorityCycleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RegionalPriorityCycle, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentRegionalPriorityCycleAdjuster: RegionalPriorityCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalPriorityCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalPriorityCycleAdjuster: RegionalPriorityCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalPriorityCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRegionalPriorityCycleAdjuster: RegionalPriorityCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalPriorityCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional priority cycle steps in order and keeps a trace of each.
    final class RegionalPriorityCycleEngine {
        var steps: [any RegionalPriorityCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalPriorityCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalPriorityCycle) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RegionalPriorityCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalPriorityCycleEngine() -> RegionalPriorityCycleEngine {
        return RegionalPriorityCycleEngine(
            steps: [
                CapRegionalPriorityCycleAdjuster(cap: 41659.0),
                RegionalPriorityCycleCapacityOffsetAdjuster(weight: 0.74),
                PercentRegionalPriorityCycleAdjuster(percent: 16.9),
                MinimumRegionalPriorityCycleAdjuster(minimum: 14.9),
                RoundingRegionalPriorityCycleAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 80358.3
        )
    }
}
