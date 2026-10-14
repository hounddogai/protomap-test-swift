import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff override calculation.
    protocol HandoffOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffOverride, value: Double) -> Double
    }

    final class HandoffOverrideCapacityOffsetAdjuster: HandoffOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: HandoffOverride, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class FlaggedHandoffOverrideAdjuster: HandoffOverrideAdjuster {
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

        func adjust(_ item: HandoffOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredHandoffOverrideAdjuster: HandoffOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the handoff override steps in order and keeps a trace of each.
    final class HandoffOverrideEngine {
        var steps: [any HandoffOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffOverride) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [HandoffOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffOverrideEngine(_ flags: Kit.Flags.Registry) -> HandoffOverrideEngine {
        return HandoffOverrideEngine(
            steps: [
                HandoffOverrideCapacityOffsetAdjuster(weight: 1.6),
                FlaggedHandoffOverrideAdjuster(flags: flags, flag: "handoff-override-lenient", percent: -9.6),
                TieredHandoffOverrideAdjuster(bounds: [2495.0, 3609.0, 5499.0, 8074.0], rates: [1.07, 0.9, 1.03, 0.9]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 25276.5
        )
    }
}
