import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning group calculation.
    protocol CleaningGroupFactor {
        func describe() -> String
        func adjust(_ item: CleaningGroup, value: Double) -> Double
    }

    final class PercentCleaningGroupAdjuster: CleaningGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCleaningGroupAdjuster: CleaningGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCleaningGroupAdjuster: CleaningGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCleaningGroupAdjuster: CleaningGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CleaningGroupUpdatedAtOffsetAdjuster: CleaningGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: CleaningGroup, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the cleaning group steps in order and keeps a trace of each.
    final class CleaningGroupEngine {
        var steps: [any CleaningGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CleaningGroup) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [CleaningGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCleaningGroupEngine() -> CleaningGroupEngine {
        return CleaningGroupEngine(
            steps: [
                PercentCleaningGroupAdjuster(percent: -16.8),
                MinimumCleaningGroupAdjuster(minimum: 29.2),
                TieredCleaningGroupAdjuster(bounds: [380.0, 1808.0, 2028.0], rates: [1.1, 1.08, 1.16]),
                RoundingCleaningGroupAdjuster(step: 0.25),
                CleaningGroupUpdatedAtOffsetAdjuster(weight: 1.74),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 17709.3
        )
    }
}
