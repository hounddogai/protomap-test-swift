import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness quota calculation.
    protocol WitnessQuotaStep {
        func describe() -> String
        func adjust(_ item: WitnessQuota, value: Double) -> Double
    }

    final class WitnessQuotaAmountOffsetAdjuster: WitnessQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: WitnessQuota, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapWitnessQuotaAdjuster: WitnessQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWitnessQuotaAdjuster: WitnessQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWitnessQuotaAdjuster: WitnessQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the witness quota steps in order and keeps a trace of each.
    final class WitnessQuotaEngine {
        var steps: [any WitnessQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessQuotaStep = steps[index]
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

        func evaluateAll(_ items: [WitnessQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessQuotaEngine() -> WitnessQuotaEngine {
        return WitnessQuotaEngine(
            steps: [
                WitnessQuotaAmountOffsetAdjuster(weight: 1.41),
                CapWitnessQuotaAdjuster(cap: 34926.0),
                MinimumWitnessQuotaAdjuster(minimum: 10.3),
                TieredWitnessQuotaAdjuster(bounds: [905.0, 1359.0], rates: [1.08, 0.92]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 49189.0
        )
    }
}
