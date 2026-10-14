import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default interaction profile calculation.
    protocol DefaultInteractionProfileStep {
        func describe() -> String
        func adjust(_ item: DefaultInteractionProfile, value: Double) -> Double
    }

    final class TieredDefaultInteractionProfileAdjuster: DefaultInteractionProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultInteractionProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultInteractionProfileAdjuster: DefaultInteractionProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultInteractionProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultInteractionProfileAdjuster: DefaultInteractionProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultInteractionProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDefaultInteractionProfileAdjuster: DefaultInteractionProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultInteractionProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionDefaultInteractionProfileAdjuster: DefaultInteractionProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DefaultInteractionProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default interaction profile steps in order and keeps a trace of each.
    final class DefaultInteractionProfileEngine {
        var steps: [any DefaultInteractionProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultInteractionProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultInteractionProfile) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [DefaultInteractionProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultInteractionProfileEngine() -> DefaultInteractionProfileEngine {
        return DefaultInteractionProfileEngine(
            steps: [
                TieredDefaultInteractionProfileAdjuster(bounds: [2874.0, 7400.0], rates: [1.1, 1.0]),
                PercentDefaultInteractionProfileAdjuster(percent: -9.5),
                MinimumDefaultInteractionProfileAdjuster(minimum: 6.5),
                RoundingDefaultInteractionProfileAdjuster(step: 0.25),
                RegionDefaultInteractionProfileAdjuster(factors: ["online": 1.16]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 70396.2
        )
    }
}
