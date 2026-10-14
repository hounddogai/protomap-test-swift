import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy revocation bundle calculation.
    protocol LegacyRevocationBundleFactor {
        func describe() -> String
        func adjust(_ item: LegacyRevocationBundle, value: Double) -> Double
    }

    final class CapLegacyRevocationBundleAdjuster: LegacyRevocationBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyRevocationBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyRevocationBundleAdjuster: LegacyRevocationBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyRevocationBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyRevocationBundleAdjuster: LegacyRevocationBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyRevocationBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyRevocationBundleAdjuster: LegacyRevocationBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyRevocationBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLegacyRevocationBundleAdjuster: LegacyRevocationBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyRevocationBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy revocation bundle steps in order and keeps a trace of each.
    final class LegacyRevocationBundleEngine {
        var steps: [any LegacyRevocationBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRevocationBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyRevocationBundle) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyRevocationBundleFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyRevocationBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyRevocationBundleEngine() -> LegacyRevocationBundleEngine {
        return LegacyRevocationBundleEngine(
            steps: [
                CapLegacyRevocationBundleAdjuster(cap: 7240.0),
                TieredLegacyRevocationBundleAdjuster(
                    bounds: [2894.0, 3022.0, 3871.0, 5643.0],
                    rates: [0.9, 1.08, 0.83, 0.99]
                ),
                MinimumLegacyRevocationBundleAdjuster(minimum: 15.9),
                PercentLegacyRevocationBundleAdjuster(percent: 10.5),
                TitleLegacyRevocationBundleAdjuster(factors: ["south": 0.83, "east": 1.11]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 5405.5
        )
    }
}
