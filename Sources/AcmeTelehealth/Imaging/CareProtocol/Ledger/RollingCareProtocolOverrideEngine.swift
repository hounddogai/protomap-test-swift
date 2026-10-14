import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling care protocol override calculation.
    protocol RollingCareProtocolOverrideFactor {
        func describe() -> String
        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double
    }

    final class RollingCareProtocolOverrideAttemptsOffsetAdjuster: RollingCareProtocolOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class PercentRollingCareProtocolOverrideAdjuster: RollingCareProtocolOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingCareProtocolOverrideAdjuster: RollingCareProtocolOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingCareProtocolOverrideAdjuster: RollingCareProtocolOverrideFactor {
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

        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryRollingCareProtocolOverrideAdjuster: RollingCareProtocolOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRollingCareProtocolOverrideAdjuster: RollingCareProtocolOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCareProtocolOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling care protocol override steps in order and keeps a trace of each.
    final class RollingCareProtocolOverrideEngine {
        var steps: [any RollingCareProtocolOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareProtocolOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingCareProtocolOverride) -> Double {
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

        func evaluateAll(_ items: [RollingCareProtocolOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingCareProtocolOverrideEngine(_ flags: Kit.Flags.Registry) -> RollingCareProtocolOverrideEngine {
        return RollingCareProtocolOverrideEngine(
            steps: [
                RollingCareProtocolOverrideAttemptsOffsetAdjuster(weight: 0.28),
                PercentRollingCareProtocolOverrideAdjuster(percent: -7.7),
                CapRollingCareProtocolOverrideAdjuster(cap: 8131.0),
                FlaggedRollingCareProtocolOverrideAdjuster(
                    flags: flags,
                    flag: "rolling-care-protocol-override-weighted",
                    percent: 5.5
                ),
                CountryRollingCareProtocolOverrideAdjuster(factors: ["north": 1.22, "west": 1.28, "south": 1.19]),
                RoundingRollingCareProtocolOverrideAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 5236.7
        )
    }
}
