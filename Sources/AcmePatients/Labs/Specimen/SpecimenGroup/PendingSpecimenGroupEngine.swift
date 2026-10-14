import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending specimen group calculation.
    protocol PendingSpecimenGroupModifier {
        func describe() -> String
        func adjust(_ item: PendingSpecimenGroup, value: Double) -> Double
    }

    final class PendingSpecimenGroupBudgetOffsetAdjuster: PendingSpecimenGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: PendingSpecimenGroup, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredPendingSpecimenGroupAdjuster: PendingSpecimenGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingSpecimenGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPendingSpecimenGroupAdjuster: PendingSpecimenGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingSpecimenGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingSpecimenGroupAdjuster: PendingSpecimenGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingSpecimenGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending specimen group steps in order and keeps a trace of each.
    final class PendingSpecimenGroupEngine {
        var steps: [any PendingSpecimenGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSpecimenGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingSpecimenGroup) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [PendingSpecimenGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingSpecimenGroupEngine() -> PendingSpecimenGroupEngine {
        return PendingSpecimenGroupEngine(
            steps: [
                PendingSpecimenGroupBudgetOffsetAdjuster(weight: 1.38),
                TieredPendingSpecimenGroupAdjuster(bounds: [3496.0, 5478.0, 8075.0], rates: [0.91, 1.1, 1.08]),
                PercentPendingSpecimenGroupAdjuster(percent: 21.2),
                MinimumPendingSpecimenGroupAdjuster(minimum: 45.5),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 68701.4
        )
    }
}
