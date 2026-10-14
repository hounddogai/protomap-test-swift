import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered read tier calculation.
    protocol TieredReadTierStep {
        func describe() -> String
        func adjust(_ item: TieredReadTier, value: Double) -> Double
    }

    final class TieredTieredReadTierAdjuster: TieredReadTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredReadTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredReadTierAdjuster: TieredReadTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredReadTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredReadTierAdjuster: TieredReadTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReadTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredReadTierAdjuster: TieredReadTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReadTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReadTierPriorityOffsetAdjuster: TieredReadTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: TieredReadTier, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the tiered read tier steps in order and keeps a trace of each.
    final class TieredReadTierEngine {
        var steps: [any TieredReadTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReadTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredReadTier) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [TieredReadTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredReadTierEngine() -> TieredReadTierEngine {
        return TieredReadTierEngine(
            steps: [
                TieredTieredReadTierAdjuster(bounds: [3764.0, 4132.0], rates: [1.16, 1.15]),
                PercentTieredReadTierAdjuster(percent: -6.2),
                MinimumTieredReadTierAdjuster(minimum: 39.4),
                CapTieredReadTierAdjuster(cap: 25204.0),
                TieredReadTierPriorityOffsetAdjuster(weight: 1.86),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 11595.4
        )
    }
}
