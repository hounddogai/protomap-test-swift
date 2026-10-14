import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach baseline calculation.
    protocol OutreachBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachBaseline, value: Double) -> Double
    }

    final class TieredOutreachBaselineAdjuster: OutreachBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingOutreachBaselineAdjuster: OutreachBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedOutreachBaselineAdjuster: OutreachBaselineAdjuster {
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

        func adjust(_ item: OutreachBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OutreachBaselineAttemptsOffsetAdjuster: OutreachBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: OutreachBaseline, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class PercentOutreachBaselineAdjuster: OutreachBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleOutreachBaselineAdjuster: OutreachBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: OutreachBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the outreach baseline steps in order and keeps a trace of each.
    final class OutreachBaselineEngine {
        var steps: [any OutreachBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachBaseline) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [OutreachBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachBaselineEngine(_ flags: Kit.Flags.Registry) -> OutreachBaselineEngine {
        return OutreachBaselineEngine(
            steps: [
                TieredOutreachBaselineAdjuster(bounds: [916.0, 3385.0, 4271.0], rates: [1.17, 0.88, 0.86]),
                RoundingOutreachBaselineAdjuster(step: 0.05),
                FlaggedOutreachBaselineAdjuster(flags: flags, flag: "outreach-baseline-primary", percent: 0.5),
                OutreachBaselineAttemptsOffsetAdjuster(weight: 1.24),
                PercentOutreachBaselineAdjuster(percent: -9.1),
                TitleOutreachBaselineAdjuster(factors: ["east": 0.7, "online": 0.88, "west": 1.3]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 18234.5
        )
    }
}
