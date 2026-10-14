import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial allocation calculation.
    protocol DenialAllocationFactor {
        func describe() -> String
        func adjust(_ item: DenialAllocation, value: Double) -> Double
    }

    final class DenialAllocationDurationMinutesOffsetAdjuster: DenialAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: DenialAllocation, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumDenialAllocationAdjuster: DenialAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleDenialAllocationAdjuster: DenialAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DenialAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the denial allocation steps in order and keeps a trace of each.
    final class DenialAllocationEngine {
        var steps: [any DenialAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialAllocation) -> Double {
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

        func evaluateAll(_ items: [DenialAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialAllocationEngine() -> DenialAllocationEngine {
        return DenialAllocationEngine(
            steps: [
                DenialAllocationDurationMinutesOffsetAdjuster(weight: 1.31),
                MinimumDenialAllocationAdjuster(minimum: 13.4),
                TitleDenialAllocationAdjuster(factors: ["east": 1.36, "central": 1.12]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 89543.7
        )
    }
}
