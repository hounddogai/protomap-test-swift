import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan threshold calculation.
    protocol DischargePlanThresholdModifier {
        func describe() -> String
        func adjust(_ item: DischargePlanThreshold, value: Double) -> Double
    }

    final class SourceDischargePlanThresholdAdjuster: DischargePlanThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DischargePlanThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDischargePlanThresholdAdjuster: DischargePlanThresholdModifier {
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

        func adjust(_ item: DischargePlanThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDischargePlanThresholdAdjuster: DischargePlanThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the discharge plan threshold steps in order and keeps a trace of each.
    final class DischargePlanThresholdEngine {
        var steps: [any DischargePlanThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanThreshold) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [DischargePlanThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanThresholdEngine(_ flags: Kit.Flags.Registry) -> DischargePlanThresholdEngine {
        return DischargePlanThresholdEngine(
            steps: [
                SourceDischargePlanThresholdAdjuster(factors: ["online": 0.85]),
                FlaggedDischargePlanThresholdAdjuster(
                    flags: flags,
                    flag: "discharge-plan-threshold-regional",
                    percent: 8.9
                ),
                TieredDischargePlanThresholdAdjuster(bounds: [1129.0, 2207.0, 7336.0], rates: [0.89, 0.83, 1.05]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 76194.6
        )
    }
}
