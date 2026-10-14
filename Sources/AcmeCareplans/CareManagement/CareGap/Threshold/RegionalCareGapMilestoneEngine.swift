import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional care gap milestone calculation.
    protocol RegionalCareGapMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalCareGapMilestone, value: Double) -> Double
    }

    final class TieredRegionalCareGapMilestoneAdjuster: RegionalCareGapMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCareGapMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameRegionalCareGapMilestoneAdjuster: RegionalCareGapMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalCareGapMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalCareGapMilestoneAdjuster: RegionalCareGapMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalCareGapMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalCareGapMilestoneAdjuster: RegionalCareGapMilestoneAdjuster {
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

        func adjust(_ item: RegionalCareGapMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional care gap milestone steps in order and keeps a trace of each.
    final class RegionalCareGapMilestoneEngine {
        var steps: [any RegionalCareGapMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareGapMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalCareGapMilestone) -> Double {
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

        func evaluateAll(_ items: [RegionalCareGapMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalCareGapMilestoneEngine(_ flags: Kit.Flags.Registry) -> RegionalCareGapMilestoneEngine {
        return RegionalCareGapMilestoneEngine(
            steps: [
                TieredRegionalCareGapMilestoneAdjuster(bounds: [143.0, 201.0], rates: [0.93, 0.96]),
                NameRegionalCareGapMilestoneAdjuster(factors: ["west": 1.16, "north": 1.01]),
                MinimumRegionalCareGapMilestoneAdjuster(minimum: 25.8),
                FlaggedRegionalCareGapMilestoneAdjuster(
                    flags: flags,
                    flag: "regional-care-gap-milestone-seasonal",
                    percent: 4.1
                ),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 55283.0
        )
    }
}
