import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict charge group calculation.
    protocol StrictChargeGroupAdjuster {
        func describe() -> String
        func adjust(_ item: StrictChargeGroup, value: Double) -> Double
    }

    final class PercentStrictChargeGroupAdjuster: StrictChargeGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictChargeGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitStrictChargeGroupAdjuster: StrictChargeGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictChargeGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStrictChargeGroupAdjuster: StrictChargeGroupAdjuster {
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

        func adjust(_ item: StrictChargeGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictChargeGroupAdjuster: StrictChargeGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictChargeGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStrictChargeGroupAdjuster: StrictChargeGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictChargeGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictChargeGroupAdjuster: StrictChargeGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictChargeGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict charge group steps in order and keeps a trace of each.
    final class StrictChargeGroupEngine {
        var steps: [any StrictChargeGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictChargeGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictChargeGroup) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [StrictChargeGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictChargeGroupEngine(_ flags: Kit.Flags.Registry) -> StrictChargeGroupEngine {
        return StrictChargeGroupEngine(
            steps: [
                PercentStrictChargeGroupAdjuster(percent: 16.8),
                UnitStrictChargeGroupAdjuster(factors: ["west": 0.83, "central": 1.19]),
                FlaggedStrictChargeGroupAdjuster(flags: flags, flag: "strict-charge-group-capped", percent: 5.3),
                RoundingStrictChargeGroupAdjuster(step: 0.05),
                MinimumStrictChargeGroupAdjuster(minimum: 6.4),
                TieredStrictChargeGroupAdjuster(
                    bounds: [3234.0, 6255.0, 7325.0, 8716.0],
                    rates: [1.18, 1.18, 1.1, 1.04]
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 5804.6
        )
    }
}
