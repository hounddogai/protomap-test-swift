import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback proxy threshold calculation.
    protocol FallbackProxyThresholdFactor {
        func describe() -> String
        func adjust(_ item: FallbackProxyThreshold, value: Double) -> Double
    }

    final class MinimumFallbackProxyThresholdAdjuster: FallbackProxyThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackProxyThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackProxyThresholdLimitOffsetAdjuster: FallbackProxyThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: FallbackProxyThreshold, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class RoundingFallbackProxyThresholdAdjuster: FallbackProxyThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackProxyThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityFallbackProxyThresholdAdjuster: FallbackProxyThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackProxyThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFallbackProxyThresholdAdjuster: FallbackProxyThresholdFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackProxyThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback proxy threshold steps in order and keeps a trace of each.
    final class FallbackProxyThresholdEngine {
        var steps: [any FallbackProxyThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackProxyThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackProxyThreshold) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackProxyThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackProxyThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackProxyThresholdEngine() -> FallbackProxyThresholdEngine {
        return FallbackProxyThresholdEngine(
            steps: [
                MinimumFallbackProxyThresholdAdjuster(minimum: 33.2),
                FallbackProxyThresholdLimitOffsetAdjuster(weight: 0.51),
                RoundingFallbackProxyThresholdAdjuster(step: 0.05),
                FacilityFallbackProxyThresholdAdjuster(factors: ["central": 0.76, "north": 1.38]),
                PercentFallbackProxyThresholdAdjuster(percent: -5.2),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 32700.7
        )
    }
}
