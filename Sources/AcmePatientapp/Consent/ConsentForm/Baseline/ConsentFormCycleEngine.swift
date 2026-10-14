import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form cycle calculation.
    protocol ConsentFormCycleAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormCycle, value: Double) -> Double
    }

    final class TieredConsentFormCycleAdjuster: ConsentFormCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedConsentFormCycleAdjuster: ConsentFormCycleAdjuster {
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

        func adjust(_ item: ConsentFormCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingConsentFormCycleAdjuster: ConsentFormCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelConsentFormCycleAdjuster: ConsentFormCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ConsentFormCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form cycle steps in order and keeps a trace of each.
    final class ConsentFormCycleEngine {
        var steps: [any ConsentFormCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormCycle) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ConsentFormCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormCycleEngine(_ flags: Kit.Flags.Registry) -> ConsentFormCycleEngine {
        return ConsentFormCycleEngine(
            steps: [
                TieredConsentFormCycleAdjuster(
                    bounds: [2304.0, 4072.0, 4652.0, 5209.0],
                    rates: [1.07, 1.11, 0.91, 1.01]
                ),
                FlaggedConsentFormCycleAdjuster(flags: flags, flag: "consent-form-cycle-rolling", percent: -6.8),
                RoundingConsentFormCycleAdjuster(step: 0.5),
                ChannelConsentFormCycleAdjuster(factors: ["north": 0.7]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 32771.0
        )
    }
}
