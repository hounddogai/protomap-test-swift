import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality rule calculation.
    protocol ModalityRuleAdjuster {
        func describe() -> String
        func adjust(_ item: ModalityRule, value: Double) -> Double
    }

    final class TieredModalityRuleAdjuster: ModalityRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumModalityRuleAdjuster: ModalityRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingModalityRuleAdjuster: ModalityRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentModalityRuleAdjuster: ModalityRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ModalityRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentModalityRuleAdjuster: ModalityRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedModalityRuleAdjuster: ModalityRuleAdjuster {
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

        func adjust(_ item: ModalityRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality rule steps in order and keeps a trace of each.
    final class ModalityRuleEngine {
        var steps: [any ModalityRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ModalityRule) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ModalityRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultModalityRuleEngine(_ flags: Kit.Flags.Registry) -> ModalityRuleEngine {
        return ModalityRuleEngine(
            steps: [
                TieredModalityRuleAdjuster(bounds: [548.0, 2456.0, 5399.0, 8107.0], rates: [1.09, 1.13, 0.89, 0.84]),
                MinimumModalityRuleAdjuster(minimum: 8.1),
                RoundingModalityRuleAdjuster(step: 0.05),
                SegmentModalityRuleAdjuster(factors: ["west": 1.33, "retail": 1.31]),
                PercentModalityRuleAdjuster(percent: 5.4),
                FlaggedModalityRuleAdjuster(flags: flags, flag: "modality-rule-primary", percent: -7.8),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 27298.2
        )
    }
}
