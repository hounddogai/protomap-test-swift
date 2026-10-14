import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient language profile calculation.
    protocol LenientLanguageProfileStep {
        func describe() -> String
        func adjust(_ item: LenientLanguageProfile, value: Double) -> Double
    }

    final class CapLenientLanguageProfileAdjuster: LenientLanguageProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientLanguageProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientLanguageProfileAdjuster: LenientLanguageProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientLanguageProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientLanguageProfileAdjuster: LenientLanguageProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientLanguageProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientLanguageProfileAdjuster: LenientLanguageProfileStep {
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

        func adjust(_ item: LenientLanguageProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionLenientLanguageProfileAdjuster: LenientLanguageProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LenientLanguageProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient language profile steps in order and keeps a trace of each.
    final class LenientLanguageProfileEngine {
        var steps: [any LenientLanguageProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientLanguageProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientLanguageProfile) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientLanguageProfileStep = steps[index]
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

        func evaluateAll(_ items: [LenientLanguageProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientLanguageProfileEngine(_ flags: Kit.Flags.Registry) -> LenientLanguageProfileEngine {
        return LenientLanguageProfileEngine(
            steps: [
                CapLenientLanguageProfileAdjuster(cap: 1183.0),
                PercentLenientLanguageProfileAdjuster(percent: 7.4),
                TieredLenientLanguageProfileAdjuster(bounds: [880.0, 3570.0, 8107.0], rates: [0.93, 0.86, 0.81]),
                FlaggedLenientLanguageProfileAdjuster(
                    flags: flags,
                    flag: "lenient-language-profile-batched",
                    percent: -7.7
                ),
                RegionLenientLanguageProfileAdjuster(factors: ["retail": 1.24, "west": 1.16, "south": 1.28]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 34549.1
        )
    }
}
