import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default rounding manifest calculation.
    protocol DefaultRoundingManifestModifier {
        func describe() -> String
        func adjust(_ item: DefaultRoundingManifest, value: Double) -> Double
    }

    final class MinimumDefaultRoundingManifestAdjuster: DefaultRoundingManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRoundingManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultRoundingManifestAdjuster: DefaultRoundingManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRoundingManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDefaultRoundingManifestAdjuster: DefaultRoundingManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRoundingManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default rounding manifest steps in order and keeps a trace of each.
    final class DefaultRoundingManifestEngine {
        var steps: [any DefaultRoundingManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRoundingManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRoundingManifest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRoundingManifestModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultRoundingManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRoundingManifestEngine() -> DefaultRoundingManifestEngine {
        return DefaultRoundingManifestEngine(
            steps: [
                MinimumDefaultRoundingManifestAdjuster(minimum: 37.6),
                TieredDefaultRoundingManifestAdjuster(
                    bounds: [8638.0, 9349.0, 9459.0, 9759.0],
                    rates: [1.15, 1.15, 0.81, 0.84]
                ),
                CapDefaultRoundingManifestAdjuster(cap: 12220.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 14052.4
        )
    }
}
