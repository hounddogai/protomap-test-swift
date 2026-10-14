import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction group calculation.
    protocol InteractionGroupAdjuster {
        func describe() -> String
        func adjust(_ item: InteractionGroup, value: Double) -> Double
    }

    final class CapInteractionGroupAdjuster: InteractionGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentInteractionGroupAdjuster: InteractionGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionGroupAdjuster: InteractionGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumInteractionGroupAdjuster: InteractionGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the interaction group steps in order and keeps a trace of each.
    final class InteractionGroupEngine {
        var steps: [any InteractionGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InteractionGroup) -> Double {
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

        func evaluateAll(_ items: [InteractionGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInteractionGroupEngine() -> InteractionGroupEngine {
        return InteractionGroupEngine(
            steps: [
                CapInteractionGroupAdjuster(cap: 40961.0),
                PercentInteractionGroupAdjuster(percent: 15.8),
                TieredInteractionGroupAdjuster(bounds: [7079.0, 7962.0], rates: [1.13, 0.87]),
                MinimumInteractionGroupAdjuster(minimum: 24.4),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 37611.7
        )
    }
}
