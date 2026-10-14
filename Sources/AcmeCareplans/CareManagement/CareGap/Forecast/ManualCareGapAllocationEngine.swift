import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual care gap allocation calculation.
    protocol ManualCareGapAllocationStep {
        func describe() -> String
        func adjust(_ item: ManualCareGapAllocation, value: Double) -> Double
    }

    final class CountryManualCareGapAllocationAdjuster: ManualCareGapAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualCareGapAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualCareGapAllocationAdjuster: ManualCareGapAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareGapAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualCareGapAllocationAdjuster: ManualCareGapAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareGapAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualCareGapAllocationCopayOffsetAdjuster: ManualCareGapAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: ManualCareGapAllocation, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class RoundingManualCareGapAllocationAdjuster: ManualCareGapAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCareGapAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual care gap allocation steps in order and keeps a trace of each.
    final class ManualCareGapAllocationEngine {
        var steps: [any ManualCareGapAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareGapAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualCareGapAllocation) -> Double {
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

        func evaluateAll(_ items: [ManualCareGapAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualCareGapAllocationEngine() -> ManualCareGapAllocationEngine {
        return ManualCareGapAllocationEngine(
            steps: [
                CountryManualCareGapAllocationAdjuster(factors: ["west": 1.05]),
                MinimumManualCareGapAllocationAdjuster(minimum: 13.9),
                PercentManualCareGapAllocationAdjuster(percent: 11.1),
                ManualCareGapAllocationCopayOffsetAdjuster(weight: 0.15),
                RoundingManualCareGapAllocationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 23253.7
        )
    }
}
