import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default claim target calculation.
    protocol DefaultClaimTargetFactor {
        func describe() -> String
        func adjust(_ item: DefaultClaimTarget, value: Double) -> Double
    }

    final class TieredDefaultClaimTargetAdjuster: DefaultClaimTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultClaimTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDefaultClaimTargetAdjuster: DefaultClaimTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultClaimTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultClaimTargetAdjuster: DefaultClaimTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultClaimTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultClaimTargetAdjuster: DefaultClaimTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultClaimTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleDefaultClaimTargetAdjuster: DefaultClaimTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultClaimTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default claim target steps in order and keeps a trace of each.
    final class DefaultClaimTargetEngine {
        var steps: [any DefaultClaimTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultClaimTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultClaimTarget) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [DefaultClaimTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultClaimTargetEngine() -> DefaultClaimTargetEngine {
        return DefaultClaimTargetEngine(
            steps: [
                TieredDefaultClaimTargetAdjuster(bounds: [1204.0, 7191.0], rates: [1.15, 1.16]),
                MinimumDefaultClaimTargetAdjuster(minimum: 18.8),
                CapDefaultClaimTargetAdjuster(cap: 16459.0),
                PercentDefaultClaimTargetAdjuster(percent: 21.6),
                TitleDefaultClaimTargetAdjuster(factors: ["retail": 1.29, "online": 0.82]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 59993.0
        )
    }
}
