import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language milestone calculation.
    protocol LanguageMilestoneFactor {
        func describe() -> String
        func adjust(_ item: LanguageMilestone, value: Double) -> Double
    }

    final class LanguageMilestoneWindowDaysOffsetAdjuster: LanguageMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: LanguageMilestone, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TieredLanguageMilestoneAdjuster: LanguageMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLanguageMilestoneAdjuster: LanguageMilestoneFactor {
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

        func adjust(_ item: LanguageMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLanguageMilestoneAdjuster: LanguageMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language milestone steps in order and keeps a trace of each.
    final class LanguageMilestoneEngine {
        var steps: [any LanguageMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageMilestone) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [LanguageMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageMilestoneEngine(_ flags: Kit.Flags.Registry) -> LanguageMilestoneEngine {
        return LanguageMilestoneEngine(
            steps: [
                LanguageMilestoneWindowDaysOffsetAdjuster(weight: 0.03),
                TieredLanguageMilestoneAdjuster(bounds: [2200.0, 6519.0], rates: [1.2, 1.13]),
                FlaggedLanguageMilestoneAdjuster(flags: flags, flag: "language-milestone-strict", percent: 1.4),
                PercentLanguageMilestoneAdjuster(percent: -21.5),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 2906.5
        )
    }
}
