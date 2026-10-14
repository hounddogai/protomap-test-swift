import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority group calculation.
    protocol PriorityGroupFactor {
        func describe() -> String
        func adjust(_ item: PriorityGroup, value: Double) -> Double
    }

    final class LabelPriorityGroupAdjuster: PriorityGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PriorityGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPriorityGroupAdjuster: PriorityGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPriorityGroupAdjuster: PriorityGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PriorityGroupRetriesOffsetAdjuster: PriorityGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PriorityGroup, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TieredPriorityGroupAdjuster: PriorityGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPriorityGroupAdjuster: PriorityGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority group steps in order and keeps a trace of each.
    final class PriorityGroupEngine {
        var steps: [any PriorityGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PriorityGroup) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [PriorityGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPriorityGroupEngine() -> PriorityGroupEngine {
        return PriorityGroupEngine(
            steps: [
                LabelPriorityGroupAdjuster(factors: ["east": 1.01, "online": 0.94, "south": 1.12]),
                CapPriorityGroupAdjuster(cap: 42152.0),
                MinimumPriorityGroupAdjuster(minimum: 22.0),
                PriorityGroupRetriesOffsetAdjuster(weight: 0.25),
                TieredPriorityGroupAdjuster(bounds: [2908.0, 4070.0, 4075.0, 7424.0], rates: [1.1, 0.93, 0.89, 0.92]),
                PercentPriorityGroupAdjuster(percent: 14.7),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 46399.5
        )
    }
}
