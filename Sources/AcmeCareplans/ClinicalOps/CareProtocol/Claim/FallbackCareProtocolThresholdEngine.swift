import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback care protocol threshold calculation.
    protocol FallbackCareProtocolThresholdFactor {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolThreshold, value: Double) -> Double
    }

    final class MinimumFallbackCareProtocolThresholdAdjuster: FallbackCareProtocolThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCareProtocolThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackCareProtocolThresholdAdjuster: FallbackCareProtocolThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCareProtocolThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFallbackCareProtocolThresholdAdjuster: FallbackCareProtocolThresholdFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCareProtocolThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback care protocol threshold steps in order and keeps a trace of each.
    final class FallbackCareProtocolThresholdEngine {
        var steps: [any FallbackCareProtocolThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCareProtocolThreshold) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCareProtocolThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackCareProtocolThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolThresholdEngine() -> FallbackCareProtocolThresholdEngine {
        return FallbackCareProtocolThresholdEngine(
            steps: [
                MinimumFallbackCareProtocolThresholdAdjuster(minimum: 27.6),
                RoundingFallbackCareProtocolThresholdAdjuster(step: 0.05),
                PercentFallbackCareProtocolThresholdAdjuster(percent: -14.9),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 59470.6
        )
    }
}
