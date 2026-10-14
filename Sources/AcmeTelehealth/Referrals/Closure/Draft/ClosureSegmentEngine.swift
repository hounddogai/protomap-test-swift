import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure segment calculation.
    protocol ClosureSegmentStep {
        func describe() -> String
        func adjust(_ item: ClosureSegment, value: Double) -> Double
    }

    final class FlaggedClosureSegmentAdjuster: ClosureSegmentStep {
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

        func adjust(_ item: ClosureSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapClosureSegmentAdjuster: ClosureSegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingClosureSegmentAdjuster: ClosureSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ClosureSegmentThresholdOffsetAdjuster: ClosureSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ClosureSegment, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredClosureSegmentAdjuster: ClosureSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the closure segment steps in order and keeps a trace of each.
    final class ClosureSegmentEngine {
        var steps: [any ClosureSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureSegment) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ClosureSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureSegmentEngine(_ flags: Kit.Flags.Registry) -> ClosureSegmentEngine {
        return ClosureSegmentEngine(
            steps: [
                FlaggedClosureSegmentAdjuster(flags: flags, flag: "closure-segment-global", percent: -3.8),
                CapClosureSegmentAdjuster(cap: 6905.0),
                RoundingClosureSegmentAdjuster(step: 0.05),
                ClosureSegmentThresholdOffsetAdjuster(weight: 1.93),
                TieredClosureSegmentAdjuster(bounds: [467.0, 701.0, 1817.0, 3015.0], rates: [0.81, 1.05, 0.92, 0.95]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 47105.6
        )
    }
}
