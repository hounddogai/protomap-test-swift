import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default outreach override calculation.
    protocol DefaultOutreachOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultOutreachOverride, value: Double) -> Double
    }

    final class TieredDefaultOutreachOverrideAdjuster: DefaultOutreachOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultOutreachOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDefaultOutreachOverrideAdjuster: DefaultOutreachOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultOutreachOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentDefaultOutreachOverrideAdjuster: DefaultOutreachOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DefaultOutreachOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultOutreachOverrideAdjuster: DefaultOutreachOverrideAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultOutreachOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default outreach override steps in order and keeps a trace of each.
    final class DefaultOutreachOverrideEngine {
        var steps: [any DefaultOutreachOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultOutreachOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultOutreachOverride) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [DefaultOutreachOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultOutreachOverrideEngine() -> DefaultOutreachOverrideEngine {
        return DefaultOutreachOverrideEngine(
            steps: [
                TieredDefaultOutreachOverrideAdjuster(bounds: [3376.0, 8917.0], rates: [1.0, 0.92]),
                MinimumDefaultOutreachOverrideAdjuster(minimum: 46.7),
                SegmentDefaultOutreachOverrideAdjuster(factors: ["retail": 1.14, "north": 1.29, "south": 1.2]),
                RoundingDefaultOutreachOverrideAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 96590.8
        )
    }
}
