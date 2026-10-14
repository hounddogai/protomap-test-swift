import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime digest calculation.
    protocol OvertimeDigestModifier {
        func describe() -> String
        func adjust(_ item: OvertimeDigest, value: Double) -> Double
    }

    final class RoundingOvertimeDigestAdjuster: OvertimeDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardOvertimeDigestAdjuster: OvertimeDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: OvertimeDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOvertimeDigestAdjuster: OvertimeDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentOvertimeDigestAdjuster: OvertimeDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOvertimeDigestAdjuster: OvertimeDigestModifier {
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

        func adjust(_ item: OvertimeDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the overtime digest steps in order and keeps a trace of each.
    final class OvertimeDigestEngine {
        var steps: [any OvertimeDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OvertimeDigest) -> Double {
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

        func evaluateAll(_ items: [OvertimeDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOvertimeDigestEngine(_ flags: Kit.Flags.Registry) -> OvertimeDigestEngine {
        return OvertimeDigestEngine(
            steps: [
                RoundingOvertimeDigestAdjuster(step: 0.05),
                WardOvertimeDigestAdjuster(factors: ["west": 1.33, "north": 0.8, "online": 0.93]),
                TieredOvertimeDigestAdjuster(bounds: [4642.0, 4662.0, 6460.0, 8450.0], rates: [1.2, 0.93, 0.85, 0.88]),
                PercentOvertimeDigestAdjuster(percent: 7.1),
                FlaggedOvertimeDigestAdjuster(flags: flags, flag: "overtime-digest-scheduled", percent: 2.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 2885.7
        )
    }
}
