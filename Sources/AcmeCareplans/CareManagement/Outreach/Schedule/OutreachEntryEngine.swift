import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach entry calculation.
    protocol OutreachEntryAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachEntry, value: Double) -> Double
    }

    final class TieredOutreachEntryAdjuster: OutreachEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumOutreachEntryAdjuster: OutreachEntryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOutreachEntryAdjuster: OutreachEntryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedOutreachEntryAdjuster: OutreachEntryAdjuster {
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

        func adjust(_ item: OutreachEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the outreach entry steps in order and keeps a trace of each.
    final class OutreachEntryEngine {
        var steps: [any OutreachEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachEntry) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachEntryAdjuster = steps[index]
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

        func evaluateAll(_ items: [OutreachEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachEntryEngine(_ flags: Kit.Flags.Registry) -> OutreachEntryEngine {
        return OutreachEntryEngine(
            steps: [
                TieredOutreachEntryAdjuster(bounds: [711.0, 2526.0, 2648.0, 8676.0], rates: [0.89, 0.84, 1.01, 0.86]),
                MinimumOutreachEntryAdjuster(minimum: 2.1),
                RoundingOutreachEntryAdjuster(step: 5.0),
                FlaggedOutreachEntryAdjuster(flags: flags, flag: "outreach-entry-batched", percent: 7.3),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 52997.0
        )
    }
}
