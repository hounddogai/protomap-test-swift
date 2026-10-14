import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy disclosure threshold calculation.
    protocol LegacyDisclosureThresholdStep {
        func describe() -> String
        func adjust(_ item: LegacyDisclosureThreshold, value: Double) -> Double
    }

    final class LegacyDisclosureThresholdRateOffsetAdjuster: LegacyDisclosureThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: LegacyDisclosureThreshold, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentLegacyDisclosureThresholdAdjuster: LegacyDisclosureThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyDisclosureThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyDisclosureThresholdAdjuster: LegacyDisclosureThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyDisclosureThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy disclosure threshold steps in order and keeps a trace of each.
    final class LegacyDisclosureThresholdEngine {
        var steps: [any LegacyDisclosureThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyDisclosureThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyDisclosureThreshold) -> Double {
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

        func evaluateAll(_ items: [LegacyDisclosureThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyDisclosureThresholdEngine() -> LegacyDisclosureThresholdEngine {
        return LegacyDisclosureThresholdEngine(
            steps: [
                LegacyDisclosureThresholdRateOffsetAdjuster(weight: 1.9),
                PercentLegacyDisclosureThresholdAdjuster(percent: -18.2),
                RoundingLegacyDisclosureThresholdAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 29115.3
        )
    }
}
