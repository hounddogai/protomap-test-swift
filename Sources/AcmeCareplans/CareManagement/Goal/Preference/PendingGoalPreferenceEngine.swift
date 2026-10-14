import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending goal preference calculation.
    protocol PendingGoalPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: PendingGoalPreference, value: Double) -> Double
    }

    final class MinimumPendingGoalPreferenceAdjuster: PendingGoalPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingGoalPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PendingGoalPreferenceMinimumOffsetAdjuster: PendingGoalPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: PendingGoalPreference, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RegionPendingGoalPreferenceAdjuster: PendingGoalPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: PendingGoalPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending goal preference steps in order and keeps a trace of each.
    final class PendingGoalPreferenceEngine {
        var steps: [any PendingGoalPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingGoalPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingGoalPreference) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [PendingGoalPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingGoalPreferenceEngine() -> PendingGoalPreferenceEngine {
        return PendingGoalPreferenceEngine(
            steps: [
                MinimumPendingGoalPreferenceAdjuster(minimum: 12.5),
                PendingGoalPreferenceMinimumOffsetAdjuster(weight: 0.54),
                RegionPendingGoalPreferenceAdjuster(factors: ["south": 1.29, "west": 1.1, "north": 1.39]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 71915.1
        )
    }
}
