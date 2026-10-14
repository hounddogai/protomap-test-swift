import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy order set threshold calculation.
    protocol LegacyOrderSetThresholdStep {
        func describe() -> String
        func adjust(_ item: LegacyOrderSetThreshold, value: Double) -> Double
    }

    final class CapLegacyOrderSetThresholdAdjuster: LegacyOrderSetThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyOrderSetThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyOrderSetThresholdAdjuster: LegacyOrderSetThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyOrderSetThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyOrderSetThresholdAdjuster: LegacyOrderSetThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyOrderSetThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyOrderSetThresholdAdjuster: LegacyOrderSetThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyOrderSetThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentLegacyOrderSetThresholdAdjuster: LegacyOrderSetThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: LegacyOrderSetThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy order set threshold steps in order and keeps a trace of each.
    final class LegacyOrderSetThresholdEngine {
        var steps: [any LegacyOrderSetThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyOrderSetThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyOrderSetThreshold) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyOrderSetThresholdStep = steps[index]
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

        func evaluateAll(_ items: [LegacyOrderSetThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyOrderSetThresholdEngine() -> LegacyOrderSetThresholdEngine {
        return LegacyOrderSetThresholdEngine(
            steps: [
                CapLegacyOrderSetThresholdAdjuster(cap: 1501.0),
                MinimumLegacyOrderSetThresholdAdjuster(minimum: 39.4),
                RoundingLegacyOrderSetThresholdAdjuster(step: 0.5),
                PercentLegacyOrderSetThresholdAdjuster(percent: 2.5),
                SegmentLegacyOrderSetThresholdAdjuster(factors: ["south": 1.35, "north": 1.32]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 98300.8
        )
    }
}
