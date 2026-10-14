import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy accession threshold calculation.
    protocol LegacyAccessionThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyAccessionThreshold, value: Double) -> Double
    }

    final class PercentLegacyAccessionThresholdAdjuster: LegacyAccessionThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAccessionThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyAccessionThresholdAdjuster: LegacyAccessionThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAccessionThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLegacyAccessionThresholdAdjuster: LegacyAccessionThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAccessionThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyAccessionThresholdAdjuster: LegacyAccessionThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAccessionThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy accession threshold steps in order and keeps a trace of each.
    final class LegacyAccessionThresholdEngine {
        var steps: [any LegacyAccessionThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAccessionThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyAccessionThreshold) -> Double {
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

        func evaluateAll(_ items: [LegacyAccessionThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyAccessionThresholdEngine() -> LegacyAccessionThresholdEngine {
        return LegacyAccessionThresholdEngine(
            steps: [
                PercentLegacyAccessionThresholdAdjuster(percent: 4.9),
                TieredLegacyAccessionThresholdAdjuster(bounds: [416.0, 9247.0], rates: [1.1, 0.84]),
                CapLegacyAccessionThresholdAdjuster(cap: 45034.0),
                MinimumLegacyAccessionThresholdAdjuster(minimum: 50.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 17097.3
        )
    }
}
