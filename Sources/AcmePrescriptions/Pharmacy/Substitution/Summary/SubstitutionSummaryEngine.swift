import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution summary calculation.
    protocol SubstitutionSummaryFactor {
        func describe() -> String
        func adjust(_ item: SubstitutionSummary, value: Double) -> Double
    }

    final class SubstitutionSummaryThresholdOffsetAdjuster: SubstitutionSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: SubstitutionSummary, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredSubstitutionSummaryAdjuster: SubstitutionSummaryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSubstitutionSummaryAdjuster: SubstitutionSummaryFactor {
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

        func adjust(_ item: SubstitutionSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution summary steps in order and keeps a trace of each.
    final class SubstitutionSummaryEngine {
        var steps: [any SubstitutionSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionSummary) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [SubstitutionSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionSummaryEngine(_ flags: Kit.Flags.Registry) -> SubstitutionSummaryEngine {
        return SubstitutionSummaryEngine(
            steps: [
                SubstitutionSummaryThresholdOffsetAdjuster(weight: 0.15),
                TieredSubstitutionSummaryAdjuster(bounds: [6798.0, 9648.0], rates: [1.08, 1.13]),
                FlaggedSubstitutionSummaryAdjuster(flags: flags, flag: "substitution-summary-tiered", percent: 9.5),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 64648.4
        )
    }
}
