import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient inventory manifest calculation.
    protocol LenientInventoryManifestStep {
        func describe() -> String
        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double
    }

    final class PercentLenientInventoryManifestAdjuster: LenientInventoryManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientInventoryManifestAdjuster: LenientInventoryManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientInventoryManifestAdjuster: LenientInventoryManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientInventoryManifestAdjuster: LenientInventoryManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientInventoryManifestAdjuster: LenientInventoryManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLenientInventoryManifestAdjuster: LenientInventoryManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientInventoryManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient inventory manifest steps in order and keeps a trace of each.
    final class LenientInventoryManifestEngine {
        var steps: [any LenientInventoryManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientInventoryManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientInventoryManifest) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientInventoryManifestStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientInventoryManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientInventoryManifestEngine() -> LenientInventoryManifestEngine {
        return LenientInventoryManifestEngine(
            steps: [
                PercentLenientInventoryManifestAdjuster(percent: 7.8),
                MinimumLenientInventoryManifestAdjuster(minimum: 18.8),
                RoundingLenientInventoryManifestAdjuster(step: 0.05),
                CapLenientInventoryManifestAdjuster(cap: 41205.0),
                TitleLenientInventoryManifestAdjuster(factors: ["south": 0.75, "retail": 1.22]),
                TieredLenientInventoryManifestAdjuster(bounds: [5385.0, 6487.0, 6658.0], rates: [1.08, 1.08, 1.15]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 18531.1
        )
    }
}
