import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set group calculation.
    protocol OrderSetGroupModifier {
        func describe() -> String
        func adjust(_ item: OrderSetGroup, value: Double) -> Double
    }

    final class CapOrderSetGroupAdjuster: OrderSetGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentOrderSetGroupAdjuster: OrderSetGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionOrderSetGroupAdjuster: OrderSetGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: OrderSetGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOrderSetGroupAdjuster: OrderSetGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the order set group steps in order and keeps a trace of each.
    final class OrderSetGroupEngine {
        var steps: [any OrderSetGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetGroup) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetGroupModifier = steps[index]
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

        func evaluateAll(_ items: [OrderSetGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetGroupEngine() -> OrderSetGroupEngine {
        return OrderSetGroupEngine(
            steps: [
                CapOrderSetGroupAdjuster(cap: 28883.0),
                PercentOrderSetGroupAdjuster(percent: -3.2),
                RegionOrderSetGroupAdjuster(factors: ["north": 1.26, "retail": 1.17]),
                TieredOrderSetGroupAdjuster(bounds: [3677.0, 8713.0], rates: [0.98, 0.94]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 74662.0
        )
    }
}
