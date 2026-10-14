import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession cycle calculation.
    protocol AccessionCycleStep {
        func describe() -> String
        func adjust(_ item: AccessionCycle, value: Double) -> Double
    }

    final class TieredAccessionCycleAdjuster: AccessionCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AccessionCycleDurationMinutesOffsetAdjuster: AccessionCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: AccessionCycle, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumAccessionCycleAdjuster: AccessionCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAccessionCycleAdjuster: AccessionCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAccessionCycleAdjuster: AccessionCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession cycle steps in order and keeps a trace of each.
    final class AccessionCycleEngine {
        var steps: [any AccessionCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionCycle) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionCycleStep = steps[index]
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

        func evaluateAll(_ items: [AccessionCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionCycleEngine() -> AccessionCycleEngine {
        return AccessionCycleEngine(
            steps: [
                TieredAccessionCycleAdjuster(bounds: [958.0, 5429.0, 6753.0, 8583.0], rates: [0.83, 1.08, 1.09, 0.85]),
                AccessionCycleDurationMinutesOffsetAdjuster(weight: 1.76),
                MinimumAccessionCycleAdjuster(minimum: 25.2),
                RoundingAccessionCycleAdjuster(step: 0.5),
                PercentAccessionCycleAdjuster(percent: 23.8),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 89854.4
        )
    }
}
