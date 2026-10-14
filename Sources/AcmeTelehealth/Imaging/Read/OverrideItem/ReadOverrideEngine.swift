import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read override calculation.
    protocol ReadOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: ReadOverride, value: Double) -> Double
    }

    final class TieredReadOverrideAdjuster: ReadOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumReadOverrideAdjuster: ReadOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityReadOverrideAdjuster: ReadOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ReadOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapReadOverrideAdjuster: ReadOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ReadOverrideAmountOffsetAdjuster: ReadOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ReadOverride, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentReadOverrideAdjuster: ReadOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read override steps in order and keeps a trace of each.
    final class ReadOverrideEngine {
        var steps: [any ReadOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReadOverride) -> Double {
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

        func evaluateAll(_ items: [ReadOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReadOverrideEngine() -> ReadOverrideEngine {
        return ReadOverrideEngine(
            steps: [
                TieredReadOverrideAdjuster(bounds: [2397.0, 3210.0, 4848.0, 8941.0], rates: [0.83, 1.09, 0.83, 1.02]),
                MinimumReadOverrideAdjuster(minimum: 25.5),
                FacilityReadOverrideAdjuster(factors: ["south": 1.31, "central": 1.39]),
                CapReadOverrideAdjuster(cap: 49029.0),
                ReadOverrideAmountOffsetAdjuster(weight: 1.34),
                PercentReadOverrideAdjuster(percent: 0.5),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 24511.2
        )
    }
}
