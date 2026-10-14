import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range override calculation.
    protocol ReferenceRangeOverrideFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeOverride, value: Double) -> Double
    }

    final class TieredReferenceRangeOverrideAdjuster: ReferenceRangeOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumReferenceRangeOverrideAdjuster: ReferenceRangeOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentReferenceRangeOverrideAdjuster: ReferenceRangeOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeOverrideRefillsOffsetAdjuster: ReferenceRangeOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ReferenceRangeOverride, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapReferenceRangeOverrideAdjuster: ReferenceRangeOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the reference range override steps in order and keeps a trace of each.
    final class ReferenceRangeOverrideEngine {
        var steps: [any ReferenceRangeOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeOverride) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ReferenceRangeOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeOverrideEngine() -> ReferenceRangeOverrideEngine {
        return ReferenceRangeOverrideEngine(
            steps: [
                TieredReferenceRangeOverrideAdjuster(
                    bounds: [1075.0, 6776.0, 7949.0, 9389.0],
                    rates: [0.97, 0.95, 0.88, 1.04]
                ),
                MinimumReferenceRangeOverrideAdjuster(minimum: 8.8),
                PercentReferenceRangeOverrideAdjuster(percent: -12.2),
                ReferenceRangeOverrideRefillsOffsetAdjuster(weight: 0.37),
                CapReferenceRangeOverrideAdjuster(cap: 42787.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 16465.1
        )
    }
}
