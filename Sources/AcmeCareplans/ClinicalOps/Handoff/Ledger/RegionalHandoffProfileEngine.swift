import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional handoff profile calculation.
    protocol RegionalHandoffProfileStep {
        func describe() -> String
        func adjust(_ item: RegionalHandoffProfile, value: Double) -> Double
    }

    final class PercentRegionalHandoffProfileAdjuster: RegionalHandoffProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalHandoffProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalHandoffProfileAdjuster: RegionalHandoffProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalHandoffProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRegionalHandoffProfileAdjuster: RegionalHandoffProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalHandoffProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalHandoffProfileAdjuster: RegionalHandoffProfileStep {
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

        func adjust(_ item: RegionalHandoffProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional handoff profile steps in order and keeps a trace of each.
    final class RegionalHandoffProfileEngine {
        var steps: [any RegionalHandoffProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalHandoffProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalHandoffProfile) -> Double {
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

        func evaluateAll(_ items: [RegionalHandoffProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalHandoffProfileEngine(_ flags: Kit.Flags.Registry) -> RegionalHandoffProfileEngine {
        return RegionalHandoffProfileEngine(
            steps: [
                PercentRegionalHandoffProfileAdjuster(percent: 12.2),
                CapRegionalHandoffProfileAdjuster(cap: 30149.0),
                MinimumRegionalHandoffProfileAdjuster(minimum: 19.5),
                FlaggedRegionalHandoffProfileAdjuster(
                    flags: flags,
                    flag: "regional-handoff-profile-weighted",
                    percent: 0.4
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 50167.8
        )
    }
}
