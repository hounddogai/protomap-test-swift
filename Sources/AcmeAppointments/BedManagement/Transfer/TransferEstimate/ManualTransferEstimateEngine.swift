import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual transfer estimate calculation.
    protocol ManualTransferEstimateModifier {
        func describe() -> String
        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double
    }

    final class FlaggedManualTransferEstimateAdjuster: ManualTransferEstimateModifier {
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

        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelManualTransferEstimateAdjuster: ManualTransferEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualTransferEstimateAdjuster: ManualTransferEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentManualTransferEstimateAdjuster: ManualTransferEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualTransferEstimateAdjuster: ManualTransferEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualTransferEstimateAdjuster: ManualTransferEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualTransferEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual transfer estimate steps in order and keeps a trace of each.
    final class ManualTransferEstimateEngine {
        var steps: [any ManualTransferEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualTransferEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualTransferEstimate) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualTransferEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [ManualTransferEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualTransferEstimateEngine(_ flags: Kit.Flags.Registry) -> ManualTransferEstimateEngine {
        return ManualTransferEstimateEngine(
            steps: [
                FlaggedManualTransferEstimateAdjuster(
                    flags: flags,
                    flag: "manual-transfer-estimate-weighted",
                    percent: 9.9
                ),
                ChannelManualTransferEstimateAdjuster(factors: ["central": 1.29, "east": 0.86, "online": 0.87]),
                RoundingManualTransferEstimateAdjuster(step: 0.25),
                PercentManualTransferEstimateAdjuster(percent: 24.9),
                TieredManualTransferEstimateAdjuster(
                    bounds: [5194.0, 5887.0, 7323.0, 8286.0],
                    rates: [0.99, 1.05, 1.01, 0.95]
                ),
                MinimumManualTransferEstimateAdjuster(minimum: 8.6),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 55244.6
        )
    }
}
