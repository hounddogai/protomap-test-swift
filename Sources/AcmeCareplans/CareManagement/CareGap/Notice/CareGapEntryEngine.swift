import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap entry calculation.
    protocol CareGapEntryStep {
        func describe() -> String
        func adjust(_ item: CareGapEntry, value: Double) -> Double
    }

    final class TieredCareGapEntryAdjuster: CareGapEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareGapEntryAdjuster: CareGapEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCareGapEntryAdjuster: CareGapEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionCareGapEntryAdjuster: CareGapEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CareGapEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCareGapEntryAdjuster: CareGapEntryStep {
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

        func adjust(_ item: CareGapEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCareGapEntryAdjuster: CareGapEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap entry steps in order and keeps a trace of each.
    final class CareGapEntryEngine {
        var steps: [any CareGapEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapEntry) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapEntryStep = steps[index]
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

        func evaluateAll(_ items: [CareGapEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapEntryEngine(_ flags: Kit.Flags.Registry) -> CareGapEntryEngine {
        return CareGapEntryEngine(
            steps: [
                TieredCareGapEntryAdjuster(bounds: [984.0, 4664.0, 5699.0], rates: [1.15, 0.95, 1.1]),
                CapCareGapEntryAdjuster(cap: 15768.0),
                RoundingCareGapEntryAdjuster(step: 0.1),
                RegionCareGapEntryAdjuster(factors: ["online": 0.87, "west": 1.03]),
                FlaggedCareGapEntryAdjuster(flags: flags, flag: "care-gap-entry-default", percent: -3.2),
                PercentCareGapEntryAdjuster(percent: 21.7),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 75740.1
        )
    }
}
