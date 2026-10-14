import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range profile calculation.
    protocol ReferenceRangeProfileModifier {
        func describe() -> String
        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double
    }

    final class FlaggedReferenceRangeProfileAdjuster: ReferenceRangeProfileModifier {
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

        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferenceRangeProfileAdjuster: ReferenceRangeProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferenceRangeProfileAdjuster: ReferenceRangeProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReferenceRangeProfileAdjuster: ReferenceRangeProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReferenceRangeProfileAdjuster: ReferenceRangeProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentReferenceRangeProfileAdjuster: ReferenceRangeProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ReferenceRangeProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range profile steps in order and keeps a trace of each.
    final class ReferenceRangeProfileEngine {
        var steps: [any ReferenceRangeProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeProfile) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ReferenceRangeProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeProfileEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeProfileEngine {
        return ReferenceRangeProfileEngine(
            steps: [
                FlaggedReferenceRangeProfileAdjuster(
                    flags: flags,
                    flag: "reference-range-profile-scheduled",
                    percent: -9.1
                ),
                RoundingReferenceRangeProfileAdjuster(step: 5.0),
                PercentReferenceRangeProfileAdjuster(percent: -7.5),
                CapReferenceRangeProfileAdjuster(cap: 23957.0),
                TieredReferenceRangeProfileAdjuster(bounds: [7497.0, 8407.0, 8995.0], rates: [0.94, 0.94, 0.95]),
                SegmentReferenceRangeProfileAdjuster(factors: ["west": 1.24, "central": 1.37]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 20183.7
        )
    }
}
