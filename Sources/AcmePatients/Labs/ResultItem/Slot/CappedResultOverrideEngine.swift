import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped result override calculation.
    protocol CappedResultOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: CappedResultOverride, value: Double) -> Double
    }

    final class CapCappedResultOverrideAdjuster: CappedResultOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedResultOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedResultOverrideAdjuster: CappedResultOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedResultOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedResultOverrideEndsAtOffsetAdjuster: CappedResultOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: CappedResultOverride, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedCappedResultOverrideAdjuster: CappedResultOverrideAdjuster {
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

        func adjust(_ item: CappedResultOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedResultOverrideAdjuster: CappedResultOverrideAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedResultOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedResultOverrideAdjuster: CappedResultOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedResultOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped result override steps in order and keeps a trace of each.
    final class CappedResultOverrideEngine {
        var steps: [any CappedResultOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedResultOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedResultOverride) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedResultOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedResultOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedResultOverrideEngine(_ flags: Kit.Flags.Registry) -> CappedResultOverrideEngine {
        return CappedResultOverrideEngine(
            steps: [
                CapCappedResultOverrideAdjuster(cap: 5729.0),
                MinimumCappedResultOverrideAdjuster(minimum: 49.3),
                CappedResultOverrideEndsAtOffsetAdjuster(weight: 1.63),
                FlaggedCappedResultOverrideAdjuster(
                    flags: flags,
                    flag: "capped-result-override-default",
                    percent: 8.4
                ),
                RoundingCappedResultOverrideAdjuster(step: 1.0),
                TieredCappedResultOverrideAdjuster(bounds: [1140.0, 7810.0], rates: [1.1, 0.9]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 34229.0
        )
    }
}
