import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback transfer plan calculation.
    protocol FallbackTransferPlanAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackTransferPlan, value: Double) -> Double
    }

    final class FallbackTransferPlanRateOffsetAdjuster: FallbackTransferPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: FallbackTransferPlan, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedFallbackTransferPlanAdjuster: FallbackTransferPlanAdjuster {
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

        func adjust(_ item: FallbackTransferPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelFallbackTransferPlanAdjuster: FallbackTransferPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FallbackTransferPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback transfer plan steps in order and keeps a trace of each.
    final class FallbackTransferPlanEngine {
        var steps: [any FallbackTransferPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackTransferPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackTransferPlan) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackTransferPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackTransferPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackTransferPlanEngine(_ flags: Kit.Flags.Registry) -> FallbackTransferPlanEngine {
        return FallbackTransferPlanEngine(
            steps: [
                FallbackTransferPlanRateOffsetAdjuster(weight: 0.42),
                FlaggedFallbackTransferPlanAdjuster(
                    flags: flags,
                    flag: "fallback-transfer-plan-legacy",
                    percent: -8.5
                ),
                LabelFallbackTransferPlanAdjuster(factors: ["west": 1.11]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 54302.8
        )
    }
}
