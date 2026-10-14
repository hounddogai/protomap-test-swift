import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled census agreement calculation.
    protocol ScheduledCensusAgreementStep {
        func describe() -> String
        func adjust(_ item: ScheduledCensusAgreement, value: Double) -> Double
    }

    final class MinimumScheduledCensusAgreementAdjuster: ScheduledCensusAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCensusAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedScheduledCensusAgreementAdjuster: ScheduledCensusAgreementStep {
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

        func adjust(_ item: ScheduledCensusAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledCensusAgreementAdjuster: ScheduledCensusAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCensusAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledCensusAgreementAdjuster: ScheduledCensusAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCensusAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledCensusAgreementAdjuster: ScheduledCensusAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCensusAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled census agreement steps in order and keeps a trace of each.
    final class ScheduledCensusAgreementEngine {
        var steps: [any ScheduledCensusAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCensusAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledCensusAgreement) -> Double {
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

        func evaluateAll(_ items: [ScheduledCensusAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledCensusAgreementEngine(_ flags: Kit.Flags.Registry) -> ScheduledCensusAgreementEngine {
        return ScheduledCensusAgreementEngine(
            steps: [
                MinimumScheduledCensusAgreementAdjuster(minimum: 47.3),
                FlaggedScheduledCensusAgreementAdjuster(
                    flags: flags,
                    flag: "scheduled-census-agreement-seasonal",
                    percent: 6.9
                ),
                TieredScheduledCensusAgreementAdjuster(bounds: [4513.0, 6062.0], rates: [0.87, 1.02]),
                RoundingScheduledCensusAgreementAdjuster(step: 0.05),
                PercentScheduledCensusAgreementAdjuster(percent: 2.4),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 57018.1
        )
    }
}
