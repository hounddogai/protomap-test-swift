import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal remittance assignment calculation.
    protocol SeasonalRemittanceAssignmentStep {
        func describe() -> String
        func adjust(_ item: SeasonalRemittanceAssignment, value: Double) -> Double
    }

    final class CapSeasonalRemittanceAssignmentAdjuster: SeasonalRemittanceAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalRemittanceAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSeasonalRemittanceAssignmentAdjuster: SeasonalRemittanceAssignmentStep {
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

        func adjust(_ item: SeasonalRemittanceAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalRemittanceAssignmentAdjuster: SeasonalRemittanceAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRemittanceAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalRemittanceAssignmentAdjuster: SeasonalRemittanceAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalRemittanceAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal remittance assignment steps in order and keeps a trace of each.
    final class SeasonalRemittanceAssignmentEngine {
        var steps: [any SeasonalRemittanceAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRemittanceAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalRemittanceAssignment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRemittanceAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalRemittanceAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalRemittanceAssignmentEngine(_ flags: Kit.Flags.Registry) -> SeasonalRemittanceAssignmentEngine {
        return SeasonalRemittanceAssignmentEngine(
            steps: [
                CapSeasonalRemittanceAssignmentAdjuster(cap: 23051.0),
                FlaggedSeasonalRemittanceAssignmentAdjuster(
                    flags: flags,
                    flag: "seasonal-remittance-assignment-tiered",
                    percent: 8.8
                ),
                MinimumSeasonalRemittanceAssignmentAdjuster(minimum: 36.3),
                TieredSeasonalRemittanceAssignmentAdjuster(
                    bounds: [4140.0, 5219.0, 5410.0, 6622.0],
                    rates: [1.05, 0.92, 1.07, 0.98]
                ),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 59248.9
        )
    }
}
