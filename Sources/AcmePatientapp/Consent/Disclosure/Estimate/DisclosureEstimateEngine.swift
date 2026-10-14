import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure estimate calculation.
    protocol DisclosureEstimateStep {
        func describe() -> String
        func adjust(_ item: DisclosureEstimate, value: Double) -> Double
    }

    final class FlaggedDisclosureEstimateAdjuster: DisclosureEstimateStep {
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

        func adjust(_ item: DisclosureEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDisclosureEstimateAdjuster: DisclosureEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDisclosureEstimateAdjuster: DisclosureEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DisclosureEstimateAmountOffsetAdjuster: DisclosureEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: DisclosureEstimate, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumDisclosureEstimateAdjuster: DisclosureEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelDisclosureEstimateAdjuster: DisclosureEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DisclosureEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure estimate steps in order and keeps a trace of each.
    final class DisclosureEstimateEngine {
        var steps: [any DisclosureEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureEstimate) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [DisclosureEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureEstimateEngine(_ flags: Kit.Flags.Registry) -> DisclosureEstimateEngine {
        return DisclosureEstimateEngine(
            steps: [
                FlaggedDisclosureEstimateAdjuster(flags: flags, flag: "disclosure-estimate-manual", percent: 8.2),
                CapDisclosureEstimateAdjuster(cap: 18220.0),
                TieredDisclosureEstimateAdjuster(
                    bounds: [166.0, 2080.0, 6336.0, 7938.0],
                    rates: [0.95, 0.91, 1.13, 1.05]
                ),
                DisclosureEstimateAmountOffsetAdjuster(weight: 0.5),
                MinimumDisclosureEstimateAdjuster(minimum: 22.5),
                LabelDisclosureEstimateAdjuster(factors: ["east": 0.79]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 2722.0
        )
    }
}
