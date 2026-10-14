import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global goal group calculation.
    protocol GlobalGoalGroupStep {
        func describe() -> String
        func adjust(_ item: GlobalGoalGroup, value: Double) -> Double
    }

    final class GlobalGoalGroupRateOffsetAdjuster: GlobalGoalGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: GlobalGoalGroup, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumGlobalGoalGroupAdjuster: GlobalGoalGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalGoalGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalGoalGroupAdjuster: GlobalGoalGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalGoalGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global goal group steps in order and keeps a trace of each.
    final class GlobalGoalGroupEngine {
        var steps: [any GlobalGoalGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalGoalGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalGoalGroup) -> Double {
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

        func evaluateAll(_ items: [GlobalGoalGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalGoalGroupEngine() -> GlobalGoalGroupEngine {
        return GlobalGoalGroupEngine(
            steps: [
                GlobalGoalGroupRateOffsetAdjuster(weight: 0.34),
                MinimumGlobalGoalGroupAdjuster(minimum: 11.8),
                CapGlobalGoalGroupAdjuster(cap: 12509.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 34379.3
        )
    }
}
