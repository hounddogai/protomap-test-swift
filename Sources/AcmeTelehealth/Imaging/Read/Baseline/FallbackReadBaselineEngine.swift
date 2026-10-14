import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback read baseline calculation.
    protocol FallbackReadBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double
    }

    final class ChannelFallbackReadBaselineAdjuster: FallbackReadBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFallbackReadBaselineAdjuster: FallbackReadBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackReadBaselineAdjuster: FallbackReadBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackReadBaselineCreatedAtOffsetAdjuster: FallbackReadBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentFallbackReadBaselineAdjuster: FallbackReadBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackReadBaselineAdjuster: FallbackReadBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackReadBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback read baseline steps in order and keeps a trace of each.
    final class FallbackReadBaselineEngine {
        var steps: [any FallbackReadBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReadBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackReadBaseline) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [FallbackReadBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackReadBaselineEngine() -> FallbackReadBaselineEngine {
        return FallbackReadBaselineEngine(
            steps: [
                ChannelFallbackReadBaselineAdjuster(factors: ["south": 0.75]),
                CapFallbackReadBaselineAdjuster(cap: 15119.0),
                TieredFallbackReadBaselineAdjuster(
                    bounds: [2063.0, 2075.0, 3415.0, 4778.0],
                    rates: [1.04, 0.93, 1.02, 0.85]
                ),
                FallbackReadBaselineCreatedAtOffsetAdjuster(weight: 1.33),
                PercentFallbackReadBaselineAdjuster(percent: 6.1),
                MinimumFallbackReadBaselineAdjuster(minimum: 16.4),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 22763.1
        )
    }
}
