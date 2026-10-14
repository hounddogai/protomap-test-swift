import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback remittance bundle calculation.
    protocol FallbackRemittanceBundleModifier {
        func describe() -> String
        func adjust(_ item: FallbackRemittanceBundle, value: Double) -> Double
    }

    final class TieredFallbackRemittanceBundleAdjuster: FallbackRemittanceBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackRemittanceBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackRemittanceBundleAdjuster: FallbackRemittanceBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackRemittanceBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackRemittanceBundleFloorValueOffsetAdjuster: FallbackRemittanceBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: FallbackRemittanceBundle, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the fallback remittance bundle steps in order and keeps a trace of each.
    final class FallbackRemittanceBundleEngine {
        var steps: [any FallbackRemittanceBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRemittanceBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackRemittanceBundle) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [FallbackRemittanceBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackRemittanceBundleEngine() -> FallbackRemittanceBundleEngine {
        return FallbackRemittanceBundleEngine(
            steps: [
                TieredFallbackRemittanceBundleAdjuster(
                    bounds: [4918.0, 5923.0, 8887.0, 8944.0],
                    rates: [0.8, 1.02, 0.89, 1.16]
                ),
                CapFallbackRemittanceBundleAdjuster(cap: 45055.0),
                FallbackRemittanceBundleFloorValueOffsetAdjuster(weight: 0.95),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 25860.4
        )
    }
}
