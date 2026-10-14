import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered consent form profile calculation.
    protocol TieredConsentFormProfileModifier {
        func describe() -> String
        func adjust(_ item: TieredConsentFormProfile, value: Double) -> Double
    }

    final class MinimumTieredConsentFormProfileAdjuster: TieredConsentFormProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredConsentFormProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredConsentFormProfileAdjuster: TieredConsentFormProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredConsentFormProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTieredConsentFormProfileAdjuster: TieredConsentFormProfileModifier {
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

        func adjust(_ item: TieredConsentFormProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered consent form profile steps in order and keeps a trace of each.
    final class TieredConsentFormProfileEngine {
        var steps: [any TieredConsentFormProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredConsentFormProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredConsentFormProfile) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredConsentFormProfileModifier = steps[index]
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

        func evaluateAll(_ items: [TieredConsentFormProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredConsentFormProfileEngine(_ flags: Kit.Flags.Registry) -> TieredConsentFormProfileEngine {
        return TieredConsentFormProfileEngine(
            steps: [
                MinimumTieredConsentFormProfileAdjuster(minimum: 34.7),
                PercentTieredConsentFormProfileAdjuster(percent: 15.7),
                FlaggedTieredConsentFormProfileAdjuster(
                    flags: flags,
                    flag: "tiered-consent-form-profile-default",
                    percent: -3.7
                ),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 3412.8
        )
    }
}
