import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global goal record calculation.
    protocol GlobalGoalRecordFactor {
        func describe() -> String
        func adjust(_ item: GlobalGoalRecord, value: Double) -> Double
    }

    final class RoundingGlobalGoalRecordAdjuster: GlobalGoalRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalGoalRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalGoalRecordAdjuster: GlobalGoalRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalGoalRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardGlobalGoalRecordAdjuster: GlobalGoalRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: GlobalGoalRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalGoalRecordWeightOffsetAdjuster: GlobalGoalRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: GlobalGoalRecord, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class CapGlobalGoalRecordAdjuster: GlobalGoalRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalGoalRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global goal record steps in order and keeps a trace of each.
    final class GlobalGoalRecordEngine {
        var steps: [any GlobalGoalRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalGoalRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalGoalRecord) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [GlobalGoalRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalGoalRecordEngine() -> GlobalGoalRecordEngine {
        return GlobalGoalRecordEngine(
            steps: [
                RoundingGlobalGoalRecordAdjuster(step: 0.25),
                MinimumGlobalGoalRecordAdjuster(minimum: 43.3),
                WardGlobalGoalRecordAdjuster(factors: ["east": 1.28, "retail": 1.32]),
                GlobalGoalRecordWeightOffsetAdjuster(weight: 0.46),
                CapGlobalGoalRecordAdjuster(cap: 32030.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 93688.1
        )
    }
}
