import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled accession target calculation.
    protocol ScheduledAccessionTargetStep {
        func describe() -> String
        func adjust(_ item: ScheduledAccessionTarget, value: Double) -> Double
    }

    final class PercentScheduledAccessionTargetAdjuster: ScheduledAccessionTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledAccessionTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledAccessionTargetAdjuster: ScheduledAccessionTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAccessionTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledAccessionTargetAdjuster: ScheduledAccessionTargetStep {
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

        func adjust(_ item: ScheduledAccessionTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledAccessionTargetAdjuster: ScheduledAccessionTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAccessionTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledAccessionTargetAdjuster: ScheduledAccessionTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledAccessionTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled accession target steps in order and keeps a trace of each.
    final class ScheduledAccessionTargetEngine {
        var steps: [any ScheduledAccessionTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAccessionTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledAccessionTarget) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAccessionTargetStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledAccessionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledAccessionTargetEngine(_ flags: Kit.Flags.Registry) -> ScheduledAccessionTargetEngine {
        return ScheduledAccessionTargetEngine(
            steps: [
                PercentScheduledAccessionTargetAdjuster(percent: 7.3),
                CapScheduledAccessionTargetAdjuster(cap: 33922.0),
                FlaggedScheduledAccessionTargetAdjuster(
                    flags: flags,
                    flag: "scheduled-accession-target-rolling",
                    percent: 6.1
                ),
                MinimumScheduledAccessionTargetAdjuster(minimum: 28.6),
                TieredScheduledAccessionTargetAdjuster(bounds: [227.0, 8185.0, 9970.0], rates: [0.85, 1.02, 0.85]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 37444.7
        )
    }
}
