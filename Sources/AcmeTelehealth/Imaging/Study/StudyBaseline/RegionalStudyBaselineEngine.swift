import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional study baseline calculation.
    protocol RegionalStudyBaselineStep {
        func describe() -> String
        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double
    }

    final class PercentRegionalStudyBaselineAdjuster: RegionalStudyBaselineStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalStudyBaselineAdjuster: RegionalStudyBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalStudyBaselineCeilingOffsetAdjuster: RegionalStudyBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FacilityRegionalStudyBaselineAdjuster: RegionalStudyBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalStudyBaselineAdjuster: RegionalStudyBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRegionalStudyBaselineAdjuster: RegionalStudyBaselineStep {
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

        func adjust(_ item: RegionalStudyBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional study baseline steps in order and keeps a trace of each.
    final class RegionalStudyBaselineEngine {
        var steps: [any RegionalStudyBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStudyBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalStudyBaseline) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RegionalStudyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalStudyBaselineEngine(_ flags: Kit.Flags.Registry) -> RegionalStudyBaselineEngine {
        return RegionalStudyBaselineEngine(
            steps: [
                PercentRegionalStudyBaselineAdjuster(percent: 18.1),
                RoundingRegionalStudyBaselineAdjuster(step: 0.1),
                RegionalStudyBaselineCeilingOffsetAdjuster(weight: 0.75),
                FacilityRegionalStudyBaselineAdjuster(factors: ["online": 1.27]),
                TieredRegionalStudyBaselineAdjuster(bounds: [5003.0, 5025.0, 8243.0], rates: [1.18, 0.99, 0.95]),
                FlaggedRegionalStudyBaselineAdjuster(
                    flags: flags,
                    flag: "regional-study-baseline-batched",
                    percent: -7.1
                ),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 98122.4
        )
    }
}
