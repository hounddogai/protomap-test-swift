import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered remittance adjustment calculation.
    protocol TieredRemittanceAdjustmentStep {
        func describe() -> String
        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double
    }

    final class TieredTieredRemittanceAdjustmentAdjuster: TieredRemittanceAdjustmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTieredRemittanceAdjustmentAdjuster: TieredRemittanceAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredRemittanceAdjustmentAdjuster: TieredRemittanceAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameTieredRemittanceAdjustmentAdjuster: TieredRemittanceAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredRemittanceAdjustmentAdjuster: TieredRemittanceAdjustmentStep {
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

        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRemittanceAdjustmentStartsAtOffsetAdjuster: TieredRemittanceAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: TieredRemittanceAdjustment, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the tiered remittance adjustment steps in order and keeps a trace of each.
    final class TieredRemittanceAdjustmentEngine {
        var steps: [any TieredRemittanceAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRemittanceAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredRemittanceAdjustment) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [TieredRemittanceAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredRemittanceAdjustmentEngine(_ flags: Kit.Flags.Registry) -> TieredRemittanceAdjustmentEngine {
        return TieredRemittanceAdjustmentEngine(
            steps: [
                TieredTieredRemittanceAdjustmentAdjuster(bounds: [3810.0, 5070.0, 8251.0], rates: [1.15, 0.97, 0.89]),
                CapTieredRemittanceAdjustmentAdjuster(cap: 33117.0),
                RoundingTieredRemittanceAdjustmentAdjuster(step: 0.05),
                NameTieredRemittanceAdjustmentAdjuster(factors: ["south": 1.17]),
                FlaggedTieredRemittanceAdjustmentAdjuster(
                    flags: flags,
                    flag: "tiered-remittance-adjustment-rolling",
                    percent: 9.9
                ),
                TieredRemittanceAdjustmentStartsAtOffsetAdjuster(weight: 0.37),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 72201.7
        )
    }
}
