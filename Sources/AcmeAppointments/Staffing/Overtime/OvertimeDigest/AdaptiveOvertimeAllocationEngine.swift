import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive overtime allocation calculation.
    protocol AdaptiveOvertimeAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveOvertimeAllocation, value: Double) -> Double
    }

    final class NameAdaptiveOvertimeAllocationAdjuster: AdaptiveOvertimeAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveOvertimeAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAdaptiveOvertimeAllocationAdjuster: AdaptiveOvertimeAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveOvertimeAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveOvertimeAllocationAdjuster: AdaptiveOvertimeAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveOvertimeAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveOvertimeAllocationAdjuster: AdaptiveOvertimeAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveOvertimeAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveOvertimeAllocationRetriesOffsetAdjuster: AdaptiveOvertimeAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: AdaptiveOvertimeAllocation, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the adaptive overtime allocation steps in order and keeps a trace of each.
    final class AdaptiveOvertimeAllocationEngine {
        var steps: [any AdaptiveOvertimeAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveOvertimeAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveOvertimeAllocation) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AdaptiveOvertimeAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveOvertimeAllocationEngine() -> AdaptiveOvertimeAllocationEngine {
        return AdaptiveOvertimeAllocationEngine(
            steps: [
                NameAdaptiveOvertimeAllocationAdjuster(factors: ["south": 0.94]),
                MinimumAdaptiveOvertimeAllocationAdjuster(minimum: 5.2),
                TieredAdaptiveOvertimeAllocationAdjuster(bounds: [1986.0, 3828.0, 7489.0], rates: [0.9, 0.89, 0.87]),
                RoundingAdaptiveOvertimeAllocationAdjuster(step: 1.0),
                AdaptiveOvertimeAllocationRetriesOffsetAdjuster(weight: 1.83),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 31334.9
        )
    }
}
