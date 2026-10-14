import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default claim bundle calculation.
    protocol DefaultClaimBundleAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double
    }

    final class TitleDefaultClaimBundleAdjuster: DefaultClaimBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultClaimBundleAdjuster: DefaultClaimBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultClaimBundleAdjuster: DefaultClaimBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDefaultClaimBundleAdjuster: DefaultClaimBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultClaimBundleQuantityOffsetAdjuster: DefaultClaimBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredDefaultClaimBundleAdjuster: DefaultClaimBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultClaimBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default claim bundle steps in order and keeps a trace of each.
    final class DefaultClaimBundleEngine {
        var steps: [any DefaultClaimBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultClaimBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultClaimBundle) -> Double {
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

        func evaluateAll(_ items: [DefaultClaimBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultClaimBundleEngine() -> DefaultClaimBundleEngine {
        return DefaultClaimBundleEngine(
            steps: [
                TitleDefaultClaimBundleAdjuster(factors: ["north": 1.22]),
                CapDefaultClaimBundleAdjuster(cap: 8856.0),
                RoundingDefaultClaimBundleAdjuster(step: 0.5),
                PercentDefaultClaimBundleAdjuster(percent: 15.3),
                DefaultClaimBundleQuantityOffsetAdjuster(weight: 1.43),
                TieredDefaultClaimBundleAdjuster(
                    bounds: [1397.0, 4449.0, 6900.0, 8243.0],
                    rates: [1.0, 0.86, 0.91, 1.19]
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 30721.2
        )
    }
}
