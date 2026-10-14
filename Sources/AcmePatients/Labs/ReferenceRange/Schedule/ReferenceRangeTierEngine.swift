import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range tier calculation.
    protocol ReferenceRangeTierAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeTier, value: Double) -> Double
    }

    final class TieredReferenceRangeTierAdjuster: ReferenceRangeTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumReferenceRangeTierAdjuster: ReferenceRangeTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentReferenceRangeTierAdjuster: ReferenceRangeTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the reference range tier steps in order and keeps a trace of each.
    final class ReferenceRangeTierEngine {
        var steps: [any ReferenceRangeTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeTier) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [ReferenceRangeTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeTierEngine() -> ReferenceRangeTierEngine {
        return ReferenceRangeTierEngine(
            steps: [
                TieredReferenceRangeTierAdjuster(bounds: [1213.0, 2663.0, 4311.0], rates: [0.87, 0.92, 1.14]),
                MinimumReferenceRangeTierAdjuster(minimum: 49.5),
                PercentReferenceRangeTierAdjuster(percent: -2.9),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 15394.5
        )
    }
}
