import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient recall milestone calculation.
    protocol LenientRecallMilestoneModifier {
        func describe() -> String
        func adjust(_ item: LenientRecallMilestone, value: Double) -> Double
    }

    final class FlaggedLenientRecallMilestoneAdjuster: LenientRecallMilestoneModifier {
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

        func adjust(_ item: LenientRecallMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientRecallMilestoneGraceDaysOffsetAdjuster: LenientRecallMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LenientRecallMilestone, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredLenientRecallMilestoneAdjuster: LenientRecallMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRecallMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientRecallMilestoneAdjuster: LenientRecallMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRecallMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelLenientRecallMilestoneAdjuster: LenientRecallMilestoneModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientRecallMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient recall milestone steps in order and keeps a trace of each.
    final class LenientRecallMilestoneEngine {
        var steps: [any LenientRecallMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRecallMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientRecallMilestone) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [LenientRecallMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientRecallMilestoneEngine(_ flags: Kit.Flags.Registry) -> LenientRecallMilestoneEngine {
        return LenientRecallMilestoneEngine(
            steps: [
                FlaggedLenientRecallMilestoneAdjuster(
                    flags: flags,
                    flag: "lenient-recall-milestone-default",
                    percent: 4.4
                ),
                LenientRecallMilestoneGraceDaysOffsetAdjuster(weight: 0.55),
                TieredLenientRecallMilestoneAdjuster(
                    bounds: [2381.0, 2770.0, 4783.0, 8771.0],
                    rates: [1.14, 1.06, 1.07, 0.99]
                ),
                MinimumLenientRecallMilestoneAdjuster(minimum: 0.1),
                LabelLenientRecallMilestoneAdjuster(factors: ["north": 0.98, "west": 1.34, "online": 1.09]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 97449.2
        )
    }
}
