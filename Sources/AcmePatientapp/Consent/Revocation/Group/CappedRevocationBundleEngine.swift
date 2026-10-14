import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped revocation bundle calculation.
    protocol CappedRevocationBundleModifier {
        func describe() -> String
        func adjust(_ item: CappedRevocationBundle, value: Double) -> Double
    }

    final class MinimumCappedRevocationBundleAdjuster: CappedRevocationBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedRevocationBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedRevocationBundleMaximumOffsetAdjuster: CappedRevocationBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CappedRevocationBundle, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class PercentCappedRevocationBundleAdjuster: CappedRevocationBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedRevocationBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedRevocationBundleAdjuster: CappedRevocationBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedRevocationBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped revocation bundle steps in order and keeps a trace of each.
    final class CappedRevocationBundleEngine {
        var steps: [any CappedRevocationBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRevocationBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedRevocationBundle) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CappedRevocationBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedRevocationBundleEngine() -> CappedRevocationBundleEngine {
        return CappedRevocationBundleEngine(
            steps: [
                MinimumCappedRevocationBundleAdjuster(minimum: 22.4),
                CappedRevocationBundleMaximumOffsetAdjuster(weight: 1.65),
                PercentCappedRevocationBundleAdjuster(percent: 15.2),
                TieredCappedRevocationBundleAdjuster(bounds: [2851.0, 3970.0], rates: [0.86, 1.16]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 61411.1
        )
    }
}
