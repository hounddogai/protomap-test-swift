import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary modality target calculation.
    protocol PrimaryModalityTargetFactor {
        func describe() -> String
        func adjust(_ item: PrimaryModalityTarget, value: Double) -> Double
    }

    final class CapPrimaryModalityTargetAdjuster: PrimaryModalityTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryModalityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryModalityTargetAdjuster: PrimaryModalityTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryModalityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryModalityTargetAdjuster: PrimaryModalityTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryModalityTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryModalityTargetAdjuster: PrimaryModalityTargetFactor {
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

        func adjust(_ item: PrimaryModalityTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryModalityTargetAdjuster: PrimaryModalityTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryModalityTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary modality target steps in order and keeps a trace of each.
    final class PrimaryModalityTargetEngine {
        var steps: [any PrimaryModalityTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryModalityTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryModalityTarget) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryModalityTargetFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryModalityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryModalityTargetEngine(_ flags: Kit.Flags.Registry) -> PrimaryModalityTargetEngine {
        return PrimaryModalityTargetEngine(
            steps: [
                CapPrimaryModalityTargetAdjuster(cap: 2680.0),
                TieredPrimaryModalityTargetAdjuster(bounds: [256.0, 1512.0, 6707.0], rates: [1.0, 1.01, 1.02]),
                PercentPrimaryModalityTargetAdjuster(percent: -2.4),
                FlaggedPrimaryModalityTargetAdjuster(
                    flags: flags,
                    flag: "primary-modality-target-regional",
                    percent: -0.9
                ),
                RoundingPrimaryModalityTargetAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 55493.8
        )
    }
}
