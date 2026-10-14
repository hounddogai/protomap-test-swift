import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial preference calculation.
    protocol DenialPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: DenialPreference, value: Double) -> Double
    }

    final class MinimumDenialPreferenceAdjuster: DenialPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDenialPreferenceAdjuster: DenialPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDenialPreferenceAdjuster: DenialPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DenialPreferenceStartsAtOffsetAdjuster: DenialPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: DenialPreference, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingDenialPreferenceAdjuster: DenialPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentDenialPreferenceAdjuster: DenialPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DenialPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the denial preference steps in order and keeps a trace of each.
    final class DenialPreferenceEngine {
        var steps: [any DenialPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DenialPreference) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [DenialPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDenialPreferenceEngine() -> DenialPreferenceEngine {
        return DenialPreferenceEngine(
            steps: [
                MinimumDenialPreferenceAdjuster(minimum: 18.1),
                TieredDenialPreferenceAdjuster(
                    bounds: [4709.0, 5990.0, 8744.0, 9330.0],
                    rates: [0.93, 1.07, 1.05, 1.04]
                ),
                PercentDenialPreferenceAdjuster(percent: 3.8),
                DenialPreferenceStartsAtOffsetAdjuster(weight: 1.24),
                RoundingDenialPreferenceAdjuster(step: 0.05),
                SegmentDenialPreferenceAdjuster(factors: ["online": 1.04]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 49254.7
        )
    }
}
