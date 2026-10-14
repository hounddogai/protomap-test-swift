import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling care protocol bundle calculation.
    protocol RollingCareProtocolBundleStep {
        func describe() -> String
        func adjust(_ item: RollingCareProtocolBundle, value: Double) -> Double
    }

    final class PercentRollingCareProtocolBundleAdjuster: RollingCareProtocolBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCareProtocolBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingCareProtocolBundleAdjuster: RollingCareProtocolBundleStep {
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

        func adjust(_ item: RollingCareProtocolBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingCareProtocolBundleAdjuster: RollingCareProtocolBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCareProtocolBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryRollingCareProtocolBundleAdjuster: RollingCareProtocolBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RollingCareProtocolBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingCareProtocolBundleGraceDaysOffsetAdjuster: RollingCareProtocolBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: RollingCareProtocolBundle, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the rolling care protocol bundle steps in order and keeps a trace of each.
    final class RollingCareProtocolBundleEngine {
        var steps: [any RollingCareProtocolBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareProtocolBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingCareProtocolBundle) -> Double {
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

        func evaluateAll(_ items: [RollingCareProtocolBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingCareProtocolBundleEngine(_ flags: Kit.Flags.Registry) -> RollingCareProtocolBundleEngine {
        return RollingCareProtocolBundleEngine(
            steps: [
                PercentRollingCareProtocolBundleAdjuster(percent: 11.6),
                FlaggedRollingCareProtocolBundleAdjuster(
                    flags: flags,
                    flag: "rolling-care-protocol-bundle-pending",
                    percent: 5.3
                ),
                CapRollingCareProtocolBundleAdjuster(cap: 27191.0),
                CountryRollingCareProtocolBundleAdjuster(factors: ["retail": 1.37]),
                RollingCareProtocolBundleGraceDaysOffsetAdjuster(weight: 0.31),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 23380.2
        )
    }
}
