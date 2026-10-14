import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default charge claim calculation.
    protocol DefaultChargeClaimStep {
        func describe() -> String
        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double
    }

    final class NameDefaultChargeClaimAdjuster: DefaultChargeClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultChargeClaimAdjuster: DefaultChargeClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultChargeClaimGraceDaysOffsetAdjuster: DefaultChargeClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredDefaultChargeClaimAdjuster: DefaultChargeClaimStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultChargeClaimAdjuster: DefaultChargeClaimStep {
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

        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultChargeClaimAdjuster: DefaultChargeClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultChargeClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default charge claim steps in order and keeps a trace of each.
    final class DefaultChargeClaimEngine {
        var steps: [any DefaultChargeClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultChargeClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultChargeClaim) -> Double {
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

        func evaluateAll(_ items: [DefaultChargeClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultChargeClaimEngine(_ flags: Kit.Flags.Registry) -> DefaultChargeClaimEngine {
        return DefaultChargeClaimEngine(
            steps: [
                NameDefaultChargeClaimAdjuster(factors: ["central": 0.97, "east": 0.82, "online": 1.17]),
                RoundingDefaultChargeClaimAdjuster(step: 0.1),
                DefaultChargeClaimGraceDaysOffsetAdjuster(weight: 1.2),
                TieredDefaultChargeClaimAdjuster(
                    bounds: [2208.0, 2601.0, 5223.0, 5910.0],
                    rates: [1.13, 0.89, 0.92, 0.84]
                ),
                FlaggedDefaultChargeClaimAdjuster(flags: flags, flag: "default-charge-claim-weighted", percent: 3.4),
                MinimumDefaultChargeClaimAdjuster(minimum: 26.1),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 15765.2
        )
    }
}
