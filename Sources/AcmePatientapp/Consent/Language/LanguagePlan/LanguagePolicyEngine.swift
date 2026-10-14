import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language policy calculation.
    protocol LanguagePolicyStep {
        func describe() -> String
        func adjust(_ item: LanguagePolicy, value: Double) -> Double
    }

    final class MinimumLanguagePolicyAdjuster: LanguagePolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguagePolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLanguagePolicyAdjuster: LanguagePolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguagePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLanguagePolicyAdjuster: LanguagePolicyStep {
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

        func adjust(_ item: LanguagePolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLanguagePolicyAdjuster: LanguagePolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguagePolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language policy steps in order and keeps a trace of each.
    final class LanguagePolicyEngine {
        var steps: [any LanguagePolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguagePolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguagePolicy) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguagePolicyStep = steps[index]
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

        func evaluateAll(_ items: [LanguagePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguagePolicyEngine(_ flags: Kit.Flags.Registry) -> LanguagePolicyEngine {
        return LanguagePolicyEngine(
            steps: [
                MinimumLanguagePolicyAdjuster(minimum: 3.3),
                TieredLanguagePolicyAdjuster(bounds: [702.0, 3828.0], rates: [1.09, 1.14]),
                FlaggedLanguagePolicyAdjuster(flags: flags, flag: "language-policy-adaptive", percent: 9.6),
                PercentLanguagePolicyAdjuster(percent: -11.8),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 27719.1
        )
    }
}
