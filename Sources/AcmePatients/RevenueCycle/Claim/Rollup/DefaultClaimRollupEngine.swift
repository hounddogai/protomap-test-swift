import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default claim rollup calculation.
    protocol DefaultClaimRollupAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultClaimRollup, value: Double) -> Double
    }

    final class RoundingDefaultClaimRollupAdjuster: DefaultClaimRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultClaimRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultClaimRollupAdjuster: DefaultClaimRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultClaimRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DefaultClaimRollupRevisionOffsetAdjuster: DefaultClaimRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: DefaultClaimRollup, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class CategoryDefaultClaimRollupAdjuster: DefaultClaimRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: DefaultClaimRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default claim rollup steps in order and keeps a trace of each.
    final class DefaultClaimRollupEngine {
        var steps: [any DefaultClaimRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultClaimRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultClaimRollup) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [DefaultClaimRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultClaimRollupEngine() -> DefaultClaimRollupEngine {
        return DefaultClaimRollupEngine(
            steps: [
                RoundingDefaultClaimRollupAdjuster(step: 5.0),
                CapDefaultClaimRollupAdjuster(cap: 4278.0),
                DefaultClaimRollupRevisionOffsetAdjuster(weight: 0.05),
                CategoryDefaultClaimRollupAdjuster(factors: ["central": 1.39, "east": 0.74]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 30025.1
        )
    }
}
