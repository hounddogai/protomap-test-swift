import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling overtime draft calculation.
    protocol RollingOvertimeDraftFactor {
        func describe() -> String
        func adjust(_ item: RollingOvertimeDraft, value: Double) -> Double
    }

    final class TieredRollingOvertimeDraftAdjuster: RollingOvertimeDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingOvertimeDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingOvertimeDraftAdjuster: RollingOvertimeDraftFactor {
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

        func adjust(_ item: RollingOvertimeDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryRollingOvertimeDraftAdjuster: RollingOvertimeDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RollingOvertimeDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingOvertimeDraftAdjuster: RollingOvertimeDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingOvertimeDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingOvertimeDraftAdjuster: RollingOvertimeDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingOvertimeDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling overtime draft steps in order and keeps a trace of each.
    final class RollingOvertimeDraftEngine {
        var steps: [any RollingOvertimeDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingOvertimeDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingOvertimeDraft) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [RollingOvertimeDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingOvertimeDraftEngine(_ flags: Kit.Flags.Registry) -> RollingOvertimeDraftEngine {
        return RollingOvertimeDraftEngine(
            steps: [
                TieredRollingOvertimeDraftAdjuster(bounds: [4622.0, 5852.0], rates: [1.14, 0.88]),
                FlaggedRollingOvertimeDraftAdjuster(flags: flags, flag: "rolling-overtime-draft-manual", percent: 0.8),
                CountryRollingOvertimeDraftAdjuster(factors: ["west": 1.28, "online": 1.02]),
                PercentRollingOvertimeDraftAdjuster(percent: 13.4),
                RoundingRollingOvertimeDraftAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 64118.7
        )
    }
}
