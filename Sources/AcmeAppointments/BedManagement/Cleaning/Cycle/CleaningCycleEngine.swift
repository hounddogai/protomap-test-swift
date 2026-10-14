import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning cycle calculation.
    protocol CleaningCycleAdjuster {
        func describe() -> String
        func adjust(_ item: CleaningCycle, value: Double) -> Double
    }

    final class PercentCleaningCycleAdjuster: CleaningCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCleaningCycleAdjuster: CleaningCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CleaningCycleRefillsOffsetAdjuster: CleaningCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: CleaningCycle, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RoundingCleaningCycleAdjuster: CleaningCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the cleaning cycle steps in order and keeps a trace of each.
    final class CleaningCycleEngine {
        var steps: [any CleaningCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningCycle) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [CleaningCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningCycleEngine() -> CleaningCycleEngine {
        return CleaningCycleEngine(
            steps: [
                PercentCleaningCycleAdjuster(percent: 3.5),
                TieredCleaningCycleAdjuster(bounds: [211.0, 6577.0], rates: [1.06, 0.93]),
                CleaningCycleRefillsOffsetAdjuster(weight: 1.6),
                RoundingCleaningCycleAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 80002.5
        )
    }
}
