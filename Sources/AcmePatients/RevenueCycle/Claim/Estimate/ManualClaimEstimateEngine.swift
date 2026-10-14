import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual claim estimate calculation.
    protocol ManualClaimEstimateStep {
        func describe() -> String
        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double
    }

    final class PercentManualClaimEstimateAdjuster: ManualClaimEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualClaimEstimateAdjuster: ManualClaimEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualClaimEstimateAdjuster: ManualClaimEstimateStep {
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

        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualClaimEstimateEndsAtOffsetAdjuster: ManualClaimEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumManualClaimEstimateAdjuster: ManualClaimEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameManualClaimEstimateAdjuster: ManualClaimEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualClaimEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual claim estimate steps in order and keeps a trace of each.
    final class ManualClaimEstimateEngine {
        var steps: [any ManualClaimEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualClaimEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualClaimEstimate) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualClaimEstimateStep = steps[index]
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

        func evaluateAll(_ items: [ManualClaimEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualClaimEstimateEngine(_ flags: Kit.Flags.Registry) -> ManualClaimEstimateEngine {
        return ManualClaimEstimateEngine(
            steps: [
                PercentManualClaimEstimateAdjuster(percent: -21.0),
                TieredManualClaimEstimateAdjuster(
                    bounds: [696.0, 3719.0, 4721.0, 8710.0],
                    rates: [0.98, 0.83, 1.1, 1.12]
                ),
                FlaggedManualClaimEstimateAdjuster(
                    flags: flags,
                    flag: "manual-claim-estimate-scheduled",
                    percent: -0.7
                ),
                ManualClaimEstimateEndsAtOffsetAdjuster(weight: 1.3),
                MinimumManualClaimEstimateAdjuster(minimum: 40.0),
                NameManualClaimEstimateAdjuster(factors: ["retail": 1.03, "south": 0.94, "west": 0.72]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 94864.9
        )
    }
}
