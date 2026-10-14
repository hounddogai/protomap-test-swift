import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional study variance calculation.
    protocol RegionalStudyVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double
    }

    final class RoundingRegionalStudyVarianceAdjuster: RegionalStudyVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRegionalStudyVarianceAdjuster: RegionalStudyVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalStudyVarianceVisitMinutesOffsetAdjuster: RegionalStudyVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedRegionalStudyVarianceAdjuster: RegionalStudyVarianceAdjuster {
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

        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRegionalStudyVarianceAdjuster: RegionalStudyVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalStudyVarianceAdjuster: RegionalStudyVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalStudyVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional study variance steps in order and keeps a trace of each.
    final class RegionalStudyVarianceEngine {
        var steps: [any RegionalStudyVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStudyVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalStudyVariance) -> Double {
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

        func evaluateAll(_ items: [RegionalStudyVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalStudyVarianceEngine(_ flags: Kit.Flags.Registry) -> RegionalStudyVarianceEngine {
        return RegionalStudyVarianceEngine(
            steps: [
                RoundingRegionalStudyVarianceAdjuster(step: 5.0),
                TieredRegionalStudyVarianceAdjuster(bounds: [2498.0, 3482.0, 7079.0], rates: [0.9, 0.88, 0.9]),
                RegionalStudyVarianceVisitMinutesOffsetAdjuster(weight: 1.71),
                FlaggedRegionalStudyVarianceAdjuster(
                    flags: flags,
                    flag: "regional-study-variance-weighted",
                    percent: 1.9
                ),
                TitleRegionalStudyVarianceAdjuster(factors: ["retail": 1.26, "online": 1.3, "north": 1.04]),
                MinimumRegionalStudyVarianceAdjuster(minimum: 9.6),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 61212.6
        )
    }
}
