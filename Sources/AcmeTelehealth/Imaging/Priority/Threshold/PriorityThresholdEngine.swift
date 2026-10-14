import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority threshold calculation.
    protocol PriorityThresholdModifier {
        func describe() -> String
        func adjust(_ item: PriorityThreshold, value: Double) -> Double
    }

    final class TieredPriorityThresholdAdjuster: PriorityThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPriorityThresholdAdjuster: PriorityThresholdModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: PriorityThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPriorityThresholdAdjuster: PriorityThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NamePriorityThresholdAdjuster: PriorityThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PriorityThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the priority threshold steps in order and keeps a trace of each.
    final class PriorityThresholdEngine {
        var steps: [any PriorityThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PriorityThreshold) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [PriorityThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPriorityThresholdEngine(_ flags: Kit.Flags.Registry) -> PriorityThresholdEngine {
        return PriorityThresholdEngine(
            steps: [
                TieredPriorityThresholdAdjuster(bounds: [99.0, 3831.0, 7170.0], rates: [0.84, 1.08, 0.88]),
                FlaggedPriorityThresholdAdjuster(flags: flags, flag: "priority-threshold-primary", percent: -1.1),
                RoundingPriorityThresholdAdjuster(step: 0.1),
                NamePriorityThresholdAdjuster(factors: ["online": 1.01]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 17146.3
        )
    }
}
