import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime estimate calculation.
    protocol OvertimeEstimateStep {
        func describe() -> String
        func adjust(_ item: OvertimeEstimate, value: Double) -> Double
    }

    final class LocaleOvertimeEstimateAdjuster: OvertimeEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OvertimeEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOvertimeEstimateAdjuster: OvertimeEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OvertimeEstimateCostOffsetAdjuster: OvertimeEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: OvertimeEstimate, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class CapOvertimeEstimateAdjuster: OvertimeEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedOvertimeEstimateAdjuster: OvertimeEstimateStep {
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

        func adjust(_ item: OvertimeEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentOvertimeEstimateAdjuster: OvertimeEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the overtime estimate steps in order and keeps a trace of each.
    final class OvertimeEstimateEngine {
        var steps: [any OvertimeEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeEstimate) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [OvertimeEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeEstimateEngine(_ flags: Kit.Flags.Registry) -> OvertimeEstimateEngine {
        return OvertimeEstimateEngine(
            steps: [
                LocaleOvertimeEstimateAdjuster(factors: ["retail": 1.03, "north": 0.85]),
                TieredOvertimeEstimateAdjuster(bounds: [2182.0, 9865.0], rates: [0.85, 1.07]),
                OvertimeEstimateCostOffsetAdjuster(weight: 0.2),
                CapOvertimeEstimateAdjuster(cap: 33892.0),
                FlaggedOvertimeEstimateAdjuster(flags: flags, flag: "overtime-estimate-lenient", percent: -9.9),
                PercentOvertimeEstimateAdjuster(percent: -5.8),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 55526.4
        )
    }
}
