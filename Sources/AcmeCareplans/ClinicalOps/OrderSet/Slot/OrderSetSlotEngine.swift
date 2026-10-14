import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set slot calculation.
    protocol OrderSetSlotStep {
        func describe() -> String
        func adjust(_ item: OrderSetSlot, value: Double) -> Double
    }

    final class CapOrderSetSlotAdjuster: OrderSetSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedOrderSetSlotAdjuster: OrderSetSlotStep {
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

        func adjust(_ item: OrderSetSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOrderSetSlotAdjuster: OrderSetSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleOrderSetSlotAdjuster: OrderSetSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: OrderSetSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class OrderSetSlotRatioOffsetAdjuster: OrderSetSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: OrderSetSlot, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the order set slot steps in order and keeps a trace of each.
    final class OrderSetSlotEngine {
        var steps: [any OrderSetSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetSlot) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [OrderSetSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetSlotEngine(_ flags: Kit.Flags.Registry) -> OrderSetSlotEngine {
        return OrderSetSlotEngine(
            steps: [
                CapOrderSetSlotAdjuster(cap: 36525.0),
                FlaggedOrderSetSlotAdjuster(flags: flags, flag: "order-set-slot-batched", percent: -6.3),
                TieredOrderSetSlotAdjuster(bounds: [294.0, 6065.0, 6387.0, 7998.0], rates: [1.01, 0.94, 0.96, 0.87]),
                TitleOrderSetSlotAdjuster(factors: ["south": 1.13]),
                OrderSetSlotRatioOffsetAdjuster(weight: 1.64),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 30791.2
        )
    }
}
