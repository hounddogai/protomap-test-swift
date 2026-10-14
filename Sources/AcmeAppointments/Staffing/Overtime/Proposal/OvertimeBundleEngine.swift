import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime bundle calculation.
    protocol OvertimeBundleStep {
        func describe() -> String
        func adjust(_ item: OvertimeBundle, value: Double) -> Double
    }

    final class MinimumOvertimeBundleAdjuster: OvertimeBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredOvertimeBundleAdjuster: OvertimeBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedOvertimeBundleAdjuster: OvertimeBundleStep {
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

        func adjust(_ item: OvertimeBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OvertimeBundleGraceDaysOffsetAdjuster: OvertimeBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: OvertimeBundle, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the overtime bundle steps in order and keeps a trace of each.
    final class OvertimeBundleEngine {
        var steps: [any OvertimeBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeBundle) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeBundleStep = steps[index]
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

        func evaluateAll(_ items: [OvertimeBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeBundleEngine(_ flags: Kit.Flags.Registry) -> OvertimeBundleEngine {
        return OvertimeBundleEngine(
            steps: [
                MinimumOvertimeBundleAdjuster(minimum: 1.8),
                TieredOvertimeBundleAdjuster(bounds: [2565.0, 3865.0, 5329.0, 9023.0], rates: [0.87, 1.06, 0.93, 1.1]),
                FlaggedOvertimeBundleAdjuster(flags: flags, flag: "overtime-bundle-rolling", percent: -3.1),
                OvertimeBundleGraceDaysOffsetAdjuster(weight: 1.28),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 65697.3
        )
    }
}
